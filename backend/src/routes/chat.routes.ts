import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import { sendMessage, getHistory, clearHistory, getConversation } from '../controllers/chat.controller';

const router = Router();

router.use(authenticate);

router.post('/message', sendMessage);
router.get('/history', getHistory);
router.delete('/history', clearHistory);
router.get('/conversation/:id', getConversation);

export default router;
