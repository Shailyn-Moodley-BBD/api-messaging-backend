CREATE TABLE UserConversations (
  user_id INT NOT NULL REFERENCES users(user_id), 
  conversation_id INT NOT NULL REFERENCES Conversations(conversation_id),
  userconversation_id INT NOT NULL,
  PRIMARY KEY (userconversation_id)
);
