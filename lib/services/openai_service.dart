// lib/services/openai_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../firebase/config/firebase_config.dart';
import '../utils/logger.dart';

class OpenAIService {
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _apiKey;

  OpenAIService() : _apiKey = FirebaseConfig.openAiKey {
    if (_apiKey.isEmpty) {
      throw Exception('OpenAI API 키가 설정되지 않았습니다.');
    }
  }

  Future<Map<String, dynamic>> analyzeNutrition({
    required List<String> foodItems,
    required String mealType,
  }) async {
    try {
      final messages = [
        {
          "role": "system",
          "content": """영양 분석 전문가로서 다음을 수행해주세요:
1. 각 음식의 GI 지수 추정
2. 영양소 분석 (탄수화물, 단백질, 지방, 칼로리)
3. 혈당 영향을 최소화하기 위한 섭취 순서 추천
4. 전반적인 식사 균형에 대한 조언

음식의 GI 지수와 영양가는 일반적인 데이터베이스 값을 기준으로 추정해주세요."""
        },
        {
          "role": "user",
          "content": """
분석할 음식: ${foodItems.join(', ')}
식사 시간: $mealType

다음 형식의 JSON으로 응답해주세요:
{
  "nutrition": {
    "giIndices": {"음식명": GI지수},
    "eatingOrder": ["순서1", "순서2"...],
    "nutrients": {
      "carbs": 0.0,
      "protein": 0.0,
      "fat": 0.0
    },
    "totalCalories": 0.0
  },
  "recommendations": ["제안1", "제안2"...]
}"""
        }
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': messages,
          'temperature': 0.7,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode != 200) {
        Logger.log('GPT 응답 오류: ${response.body}');
        throw Exception('영양 분석 요청 실패: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      return jsonDecode(data['choices'][0]['message']['content']);
    } catch (e) {
      Logger.log('OpenAI 서비스 오류: $e');
      throw Exception('영양 분석 중 오류가 발생했습니다');
    }
  }
}
