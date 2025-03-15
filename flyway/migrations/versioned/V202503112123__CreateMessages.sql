CREATE TABLE messages (
    message_id SERIAL PRIMARY KEY,
    sender_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    receiver_id INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_bool BOOLEAN DEFAULT FALSE
);