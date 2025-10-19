import 'package:pedal/models/notice.dart';

final List<Notice> mockNotices = [
  Notice(
    id: 1,
    title: '페달 서비스 정식 출시 안내',
    content:
        '''안녕하세요, 페달 팀입니다. 

안전하고 즐거운 라이딩을 위한 페달 서비스가 정식 출시되었습니다. 

많은 이용 부탁드립니다. 

감사합니다.''',
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
  ),
  Notice(
    id: 2,
    title: '개인정보 처리방침 변경 안내',
    content:
        '''안녕하세요, 페달 팀입니다. 

개인정보 처리방침이 일부 변경되어 안내드립니다. 

자세한 내용은 앱 내 개인정보 처리방침을 확인해주세요. 

감사합니다.''',
    createdAt: DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
    updatedAt: DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
  ),
  Notice(
    id: 3,
    title: '서비스 점검 안내 (오전 2시 - 4시)',
    content:
        '''안녕하세요, 페달 팀입니다. 

보다 안정적인 서비스 제공을 위해 시스템 점검을 진행할 예정입니다. 

점검 시간에는 서비스 이용이 원활하지 않을 수 있으니 양해 부탁드립니다. 

- 점검 시간: 오늘 오전 2시 ~ 4시 

감사합니다.''',
    createdAt: DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
    updatedAt:
        DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
  ),
  Notice(
    id: 4,
    title: '신규 기능 ‘경로 공유’ 업데이트 안내',
    content: '이제 라이딩 경로를 친구들과 공유할 수 있습니다. 마이페이지에서 공유하고 싶은 경로를 선택하여 공유해보세요!',
    createdAt: DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
    updatedAt: DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
  ),
  Notice(
    id: 5,
    title: '추석 연휴 고객센터 운영 안내',
    content: '추석 연휴 기간 동안 고객센터 운영 시간이 단축됩니다. 1:1 문의 답변이 지연될 수 있는 점 양해 부탁드립니다.',
    createdAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    updatedAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
  ),
  Notice(
    id: 6,
    title: 'v1.1.0 앱 업데이트 안내',
    content: '지도 정확성 개선 및 일부 버그가 수정되었습니다. 더 나은 서비스를 위해 앱을 최신 버전으로 업데이트해주세요.',
    createdAt: DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
    updatedAt: DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
  ),
  Notice(
    id: 7,
    title: '일부 기기에서 접속이 불안정한 현상에 대한 안내',
    content: '현재 일부 안드로이드 기기에서 접속이 불안정한 현상이 확인되어 원인을 파악 중에 있습니다. 불편을 드려 죄송합니다.',
    createdAt: DateTime.now().subtract(const Duration(days: 50)).toIso8601String(),
    updatedAt: DateTime.now().subtract(const Duration(days: 50)).toIso8601String(),
  ),
  Notice(
    id: 8,
    title: '[완료] 서비스 안정화를 위한 서버 점검',
    content: '서버 점검이 완료되었습니다. 현재 정상적으로 서비스 이용이 가능합니다. 기다려주셔서 감사합니다.',
    createdAt: DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
    updatedAt: DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
  ),
  Notice(
    id: 9,
    title: '더 나은 페달을 위한 사용자 설문조사',
    content: '페달 서비스 발전을 위해 사용자 여러분의 소중한 의견을 듣습니다. 설문에 참여하여 의견을 들려주세요. (추첨을 통해 소정의 상품 증정)',
    createdAt: DateTime.now().subtract(const Duration(days: 75)).toIso8601String(),
    updatedAt: DateTime.now().subtract(const Duration(days: 75)).toIso8601String(),
  ),
  Notice(
    id: 10,
    title: '이용약관 개정 안내',
    content: '서비스 이용약관이 개정되었습니다. 변경된 내용은 2025년 12월 1일부터 효력이 발생합니다.',
    createdAt: DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
    updatedAt: DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
  ),
];