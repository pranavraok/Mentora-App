-- Add user_id column to projects table for ownership tracking
-- Allows projects to be owned by specific users (global templates have NULL user_id)

ALTER TABLE projects
ADD COLUMN user_id UUID REFERENCES users(id) ON DELETE CASCADE;

-- Create index for faster filtering by user_id
CREATE INDEX idx_projects_user_id ON projects(user_id);

-- Create index for filtering global templates and user projects
CREATE INDEX idx_projects_user_id_nullable ON projects(user_id) WHERE user_id IS NULL;

-- Update schema.sql comment to document this change
-- Projects with user_id = NULL are global templates
-- Projects with user_id = <uuid> are owned by that user
