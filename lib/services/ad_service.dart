class AdService {
  Future<bool> showAd() async {
    // 여기에 실제 광고 표시 로직을 구현합니다.
    // 지금은 항상 true를 반환하도록 설정했습니다.
    await Future.delayed(Duration(seconds: 1)); // 광고 표시를 시뮬레이션
    return true;
  }
}