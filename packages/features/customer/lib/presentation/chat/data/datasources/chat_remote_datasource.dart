import 'package:dio/dio.dart';
import '../models/chat_message_model.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatMessageModel>> getHistory();
  Future<ChatMessageModel> sendMessage(String content);
  Future<void> clearHistory();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final Dio dio;

  ChatRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ChatMessageModel>> getHistory() async {
    final res = await dio.get('/chat/history');
    final data = res.data['data'] as List;
    
    // API trả về list conversations, lấy messages từ conversation đầu tiên
    if (data.isEmpty) return [];
    
    final firstConv = data[0] as Map<String, dynamic>;
    final messages = firstConv['messages'] as List;
    
    return messages
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChatMessageModel> sendMessage(String content) async {
    try {
      final res = await dio.post('/chat/message', data: {'content': content});
      print('Response status: ${res.statusCode}');
      print('Response data: ${res.data}');
      
      final data = res.data['data'] as Map<String, dynamic>;
      
      // API trả về {reply, conversationId}, chuyển thành ChatMessageModel
      return ChatMessageModel.botMessage(
        id: data['conversationId'] as String,
        content: data['reply'] as String,
      );
    } catch (e, stackTrace) {
      print('Error in sendMessage: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> clearHistory() async {
    await dio.delete('/chat/history');
  }
}
