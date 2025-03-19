CREATE TABLE UserConversations (
  UserID INT NOT NULL REFERENCES Users(UserID),
  ConversationID INT NOT NULL REFERENCES Conversations(ConversationID),
  PRIMARY KEY (UserID, ConversationID)
);