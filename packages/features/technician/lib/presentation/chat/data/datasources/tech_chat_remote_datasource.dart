import 'package:dio/dio.dart';
import '../models/tech_chat_message_model.dart';

abstract class TechChatRemoteDataSource {
  Future<List<TechChatMessageModel>> getHistory();
  Future<TechChatMessageModel> sendMessage(String content);
  Future<void> clearHistory();
}

class TechChatRemoteDataSourceImpl implements TechChatRemoteDataSource {
  final Dio dio;

  TechChatRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<TechChatMessageModel>> getHistory() async {
    final res = await dio.get('/chat/history');
    final data = res.data['data'] as List;
    if (data.isEmpty) return [];
    final firstConv = data[0] as Map<String, dynamic>;
    final messages = firstConv['messages'] as List;
    return messages
        .map((e) => TechChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TechChatMessageModel> sendMessage(String content) async {
    try {
      final res = await dio.post('/chat/message', data: {
        'content': content,
        'role': 'technician',
      });
      final data = res.data['data'] as Map<String, dynamic>;
      return TechChatMessageModel.botMessage(
        id: data['conversationId'] as String,
        content: data['reply'] as String,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clearHistory() async {
    await dio.delete('/chat/history');
  }
}
