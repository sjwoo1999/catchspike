// lib/services/meal_analysis_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

class MealAnalysisService {
  final String? _apiKey = dotenv.env['OPENAI_API_KEY'];

  Future<Map<String, dynamic>> analyzeMealImage(String imageUrl) async {
    if (_apiKey == null) {
      throw Exception('OpenAI API Key가 설정되지 않았습니다.');
    }

    try {
      // Firebase Storage URL을 base64로 변환
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('이미지 다운로드 실패: ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      final base64Image = base64Encode(bytes);

      // GPT-4 Vision API 호출
      final gptResponse = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'gpt-4-vision-preview',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': '''이 식사 이미지를 분석하고 다음 정보를 제공해주세요:
1. 확인된 음식 목록
2. 각 음식의 예상 칼로리
3. 영양 성분 분석 (탄수화물, 단백질, 지방)
4. 건강한 식사를 위한 제안
JSON 형식으로 응답해주세요.'''
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                }
              ],
            }
          ],
          'max_tokens': 1000,
        }),
      );

      if (gptResponse.statusCode == 200) {
        final data = json.decode(gptResponse.body);
        final content = data['choices'][0]['message']['content'];
        return json.decode(content);
      }

      throw Exception('이미지 분석 실패: ${gptResponse.statusCode}');
    } catch (e) {
      Logger.log('이미지 분석 중 오류 발생: $e');
      rethrow;
    }
  }
}
