// lib/services/openai_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // TimeoutException을 사용하기 위해 추가
import '../firebase/config/firebase_config.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart'; // OpenAIException 임포트 추가

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const Duration _defaultTimeout = Duration(seconds: 30);

  final String _apiKey;
  final String _model;

  OpenAIService({String? model})
      : _apiKey = FirebaseConfig.openAiKey,
        _model = model ?? FirebaseConfig.openAiModel {
    if (!FirebaseConfig.isOpenAIConfigured) {
      throw const OpenAIException('OpenAI 설정이 완료되지 않았습니다.');
    }
  }

  Future<Map<String, dynamic>> analyzeNutrition({
    required List<String> foodItems,
    required String mealType,
  }) async {
    try {
      if (foodItems.isEmpty) {
        throw const OpenAIException('분석할 음식 항목이 없습니다.');
      }

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

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 1000,
            }),
          )
          .timeout(_defaultTimeout);

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw OpenAIException(
          error['error']['message'] ?? '영양 분석 요청 실패',
          code: error['error']['code'],
        );
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];

      // JSON 파싱 시도
      Map<String, dynamic> parsedResponse;
      try {
        parsedResponse = jsonDecode(content);
      } catch (e) {
        throw OpenAIException(
          'OpenAI 응답을 JSON으로 변환하는 데 실패했습니다. 응답 내용: $content',
        );
      }

      return parsedResponse;
    } on TimeoutException {
      throw const OpenAIException('요청 시간이 초과되었습니다.');
    } on OpenAIException {
      rethrow;
    } catch (e) {
      Logger.log('OpenAI 서비스 오류: $e');
      throw OpenAIException('영양 분석 중 오류가 발생했습니다: $e');
    }
  }
}
