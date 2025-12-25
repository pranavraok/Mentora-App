// =====================================================
// RESUME ANALYSIS BACKEND SERVER
// =====================================================
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const axios = require('axios');
const pdfParse = require('pdf-parse');

const app = express();
const PORT = process.env.PORT || 3001;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

// Configure CORS - allow requests from Flutter web
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['http://localhost:3000', 'http://localhost:52100'];

app.use(cors({
  origin: function(origin, callback) {
    // Allow requests with no origin (like mobile apps or Postman)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      // For development, allow any localhost
      if (origin.startsWith('http://localhost:')) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    }
  },
  credentials: true
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Resume backend is running' });
});

// Resume analysis endpoint
app.post('/api/resume/analyze', async (req, res) => {
  console.log('\n=== RESUME ANALYSIS REQUEST RECEIVED ===');
  console.log('Timestamp:', new Date().toISOString());
  console.log('Request body keys:', Object.keys(req.body));
  console.log('============================================\n');
  
  try {
    const { resumeUrl, userId } = req.body;

    if (!resumeUrl || !userId) {
      console.error('ERROR: Missing required fields');
      return res.status(400).json({
        error: 'resumeUrl and userId are required'
      });
    }

    console.log(`Analyzing resume for user: ${userId}`);
    console.log(`Resume URL: ${resumeUrl}`);

    // Download the PDF from Supabase Storage
    const pdfResponse = await axios.get(resumeUrl, {
      responseType: 'arraybuffer'
    });

    // Extract text from PDF
    const pdfData = await pdfParse(pdfResponse.data);
    const resumeText = pdfData.text;

    if (!resumeText || resumeText.trim().length < 50) {
      return res.status(400).json({
        error: 'Could not extract sufficient text from PDF'
      });
    }

    console.log(`Extracted ${resumeText.length} characters from PDF`);

    // Analyze with Gemini AI
    const analysis = await analyzeWithGemini(resumeText);

    // Convert to camelCase and return structured response matching Flutter expectations
    const responseData = {
      overallScore: analysis.overall_score || 0,
      techScore: analysis.tech_score || 0,
      readabilityScore: analysis.readability_score || 0,
      suggestions: analysis.suggestions || []
    };

    console.log('=== SENDING RESPONSE TO FLUTTER ===');
    console.log('Response keys:', Object.keys(responseData));
    console.log('Scores:', { overallScore: responseData.overallScore, techScore: responseData.techScore, readabilityScore: responseData.readabilityScore });
    console.log('Suggestions count:', responseData.suggestions.length);
    console.log('===================================');

    res.json(responseData);

  } catch (error) {
    console.error('Error analyzing resume:', error.message);
    res.status(500).json({
      error: error.message || 'Failed to analyze resume'
    });
  }
});

// Function to call Gemini API
async function analyzeWithGemini(resumeText) {
  const prompt = `Analyze this resume and provide scores and suggestions:

RESUME TEXT:
${resumeText}

Provide your analysis in this EXACT JSON format (no markdown, just raw JSON):
{
  "overall_score": <number 0-100>,
  "tech_score": <number 0-100>,
  "readability_score": <number 0-100>,
  "suggestions": [
    {"title": "Suggestion title", "detail": "Detailed explanation"},
    {"title": "Another suggestion", "detail": "More details"}
  ]
}

Analyze for:
1. Overall resume quality (overall_score)
2. Technical skills and content (tech_score)
3. Readability and formatting (readability_score)
4. Provide 3-5 specific, actionable suggestions to improve the resume`;

  try {
    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${GEMINI_API_KEY}`,
      {
        contents: [{
          parts: [{
            text: prompt
          }]
        }],
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        }
      },
      {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    const generatedText = response.data.candidates[0].content.parts[0].text;
    
    // Extract JSON from response (remove markdown code blocks if present)
    let jsonText = generatedText.trim();
    if (jsonText.startsWith('```json')) {
      jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    } else if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/```\n?/g, '');
    }
    
    const analysis = JSON.parse(jsonText);
    return analysis;

  } catch (error) {
    console.error('Gemini API error:', error.response?.data || error.message);
    
    // Return fallback scores if Gemini fails
    return {
      overall_score: 50,
      tech_score: 50,
      readability_score: 50,
      suggestions: [
        {
          title: 'AI Analysis Unavailable',
          detail: 'The AI service is currently unavailable. Please try again later.'
        }
      ]
    };
  }
}

// Start server
app.listen(PORT, () => {
  console.log(`Resume backend server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Resume analysis: POST http://localhost:${PORT}/api/resume/analyze`);
});
