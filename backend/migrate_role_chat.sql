ALTER TABLE users ADD COLUMN role ENUM('patient','caregiver') NOT NULL DEFAULT 'patient' AFTER password;

CREATE TABLE IF NOT EXISTS chat_messages (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  senderId BIGINT UNSIGNED NOT NULL,
  receiverId BIGINT UNSIGNED NOT NULL,
  message TEXT NOT NULL,
  isRead TINYINT(1) NOT NULL DEFAULT 0,
  createdAt DATETIME NOT NULL,
  updatedAt DATETIME NOT NULL,
  KEY chat_sender_receiver (senderId, receiverId),
  CONSTRAINT chat_messages_sender_fk FOREIGN KEY (senderId) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chat_messages_receiver_fk FOREIGN KEY (receiverId) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
