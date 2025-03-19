CREATE TABLE Conversations (
  conversation_id SERIAL PRIMARY KEY, 
  conversation_name VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);