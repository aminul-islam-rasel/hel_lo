import 'package:flutter_test/flutter_test.dart';
import 'package:hel_lo/core/utils/conversation_utils.dart';
import 'package:hel_lo/main.dart';

void main() {
  group('Hel Lo App & Utility Tests', () {
    test('App widget is defined', () {
      expect(WhatsAppApp, isNotNull);
    });

    test('Conversation ID generation is deterministic and sorted', () {
      final id1 = ConversationUtils.generateConversationId('userB', 'userA');
      final id2 = ConversationUtils.generateConversationId('userA', 'userB');
      expect(id1, equals(id2));
      expect(id1, equals('conv_userA_userB'));
    });
  });
}
