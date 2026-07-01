import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import { 
  sendMessage, 
  getHistory, 
  clearHistory, 
  getConversation,
  getDirectConversation,
  sendDirectMessage,
  getTechConversations,
  getDirectHistory
} from '../controllers/chat.controller';

const router = Router();

router.use(authenticate);

// AI Chatbot routes
router.post('/message', sendMessage);
router.get('/history', getHistory);
router.delete('/history', clearHistory);
router.get('/conversation/:id', getConversation);

// Customer <-> Technician Direct Chat routes
router.get('/direct/conversation', getDirectConversation);
router.post('/direct/message', sendDirectMessage);
router.get('/direct/conversations/tech', getTechConversations);
router.get('/direct/history/:conversationId', getDirectHistory);

export default router;
