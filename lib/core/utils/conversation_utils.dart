class ConversationUtils {
  static String generateConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return 'conv_${sorted[0]}_${sorted[1]}';
  }
}
