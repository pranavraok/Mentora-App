# Resume Analysis Backend

Node.js/Express backend for AI-powered resume analysis using Google Gemini.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Make sure `.env` file has:
```
PORT=3002
GEMINI_API_KEY=your_gemini_api_key_here
ALLOWED_ORIGINS=http://localhost:52100,http://localhost:3000
```

3. Start server:
```bash
npm start
```

Server will run on http://localhost:3002

## API Endpoints

### Health Check
```
GET /health
```
Returns: `{ status: 'ok', message: 'Resume backend is running' }`

### Analyze Resume
```
POST /api/resume/analyze
Content-Type: application/json

{
  "resumeUrl": "https://your-supabase-storage-url/resume.pdf",
  "userId": "user-id-from-supabase"
}
```

Returns:
```json
{
  "overallScore": 85,
  "techScore": 90,
  "readabilityScore": 80,
  "suggestions": [
    {
      "title": "Add More Quantifiable Achievements",
      "detail": "Include specific metrics and numbers to demonstrate impact"
    }
  ]
}
```

## How It Works

1. Receives resume URL from Flutter app
2. Downloads PDF from Supabase Storage
3. Extracts text using pdf-parse
4. Analyzes text with Google Gemini AI
5. Returns structured scores and suggestions

## Tech Stack

- Express.js - Web framework
- pdf-parse - PDF text extraction
- Axios - HTTP client for Gemini API
- CORS - Cross-origin support for Flutter web
