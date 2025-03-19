CREATE TABLE UserConversations (
  user_id INT NOT NULL REFERENCES users(user_id), 
  conversation_id INT NOT NULL REFERENCES Conversations(conversation_id),
  PRIMARY KEY (user_id, conversation_id)
);
