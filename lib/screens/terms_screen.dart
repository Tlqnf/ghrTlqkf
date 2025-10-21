import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  final String type; // 'terms' or 'privacy'

  const TermsScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    // type에 따라 데이터 선택
    final List<Map<String, String>> contentList =
    (type == 'privacy') ? privacyPolicy : termsOfService;

    // 앱바 타이틀 설정
    final String appBarTitle =
    (type == 'privacy') ? '개인정보 처리방침' : '서비스 이용약관';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        flexibleSpace: Container(color: Theme.of(context).colorScheme.surface),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: contentList.map((item) {
              switch (item['type']) {
                case 'title':
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      item['content'] ?? '',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  );
                case 'subtitle':
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(
                      item['content'] ?? '',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  );
                case 'body':
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      item['content'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                case 'space':
                default:
                  return const SizedBox(height: 8);
              }
            }).toList(),
          ),
        ),
      ),
    );
  }
}

final List<Map<String, String>> termsOfService = [
  {'type': 'title', 'content': '서비스 이용약관'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제1조 (목적)'},
  {'type': 'body', 'content': '이 약관은 뉴클이 제공하는 "페달" 앱의 이용조건 및 절차, 회사와 이용자의 권리·의무·책임사항을 규정함을 목적으로 합니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제2조 (정의)'},
  {'type': 'body', 'content': '1. “서비스”라 함은 회사가 모바일 앱·웹을 통해 제공하는 자전거 경로 자동추적·저장·공유 기능 및 부가 서비스를 말합니다.'},
  {'type': 'body', 'content': '2. “이용자”는 본 약관에 따라 서비스를 이용하는 회원과 비회원을 포함합니다.'},
  {'type': 'body', 'content': '3. “회원”은 회사에 개인정보를 제공하고 회원가입을 한 자로 회사로부터 서비스를 지속적으로 제공받는 자를 말합니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제3조 (약관의 효력·개정)'},
  {'type': 'body', 'content': '1. 본 약관은 서비스 초기화면 또는 앱 내 연결화면에 게시하거나, 전자우편·앱 푸시로 통지한 시점부터 효력이 발생합니다.'},
  {'type': 'body', 'content': '2. 회사는 관련법령을 위배하지 않는 범위에서 약관을 개정할 수 있으며, 중요한 변경 시에는 최소 30일 전에 공지합니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제4조 (서비스의 제공 및 변경)'},
  {'type': 'body', 'content': '1. 회사는 아래 서비스를 제공합니다: 경로 자동추적, 경로 저장, 경로 편집, 공개/비공개 공유, 커뮤니티 기능, 통계·분석 기능 등.'},
  {'type': 'body', 'content': '2. 회사는 서비스의 일부 또는 전부를 운영상·기술상 필요에 따라 변경·중단할 수 있으며, 사전 공지합니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제5조 (회원가입 및 계정 관리)'},
  {'type': 'body', 'content': '1. 회원가입 시 이용자는 정확한 정보 제공에 동의해야 하며, 변경 시 즉시 수정해야 합니다.'},
  {'type': 'body', 'content': '2. 계정은 본인만 사용해야 하며 계정 보안(비밀번호 등)은 회원 책임입니다. 타인 사용으로 인한 손해는 회원이 부담합니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제6조 (위치정보 및 추적 관련 동의)'},
  {'type': 'body', 'content': '1. 본 서비스는 GPS·센서 등을 이용하여 이동 경로(위치정보)를 자동으로 수집·처리합니다.'},
  {'type': 'body', 'content': '2. 이용자는 앱 권한 허용을 통해 명시적으로 위치정보 수집·이용에 동의해야 하며, 동의 철회(권한 해제) 시 서비스 일부가 제한될 수 있습니다.'},
  {'type': 'body', 'content': '3. 위치정보의 실시간 전송·공개 기능은 사용자가 별도 설정으로 허용한 경우에만 적용됩니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제7조 (사용자의 의무)'},
  {'type': 'body', 'content': '1. 이용자는 관련법령 및 약관을 준수해야 하며, 서비스 이용과정에서 타인의 권리(프라이버시·저작권 등)를 침해하지 않아야 합니다.'},
  {'type': 'body', 'content': '2. 불법·유해한 목적, 범죄 행위, 타인 비방·명예훼손, 개인정보 무단수집·게시 등을 금지합니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제8조 (게시물의 관리 및 저작권)'},
  {'type': 'body', 'content': '1. 이용자가 서비스에 업로드한 경로·사진·댓글 등의 게시물(이하 “게시물”)의 저작권은 게시자에게 있습니다.'},
  {'type': 'body', 'content': '2. 단, 이용자는 회사가 서비스 운영·홍보·통계 목적 등으로 해당 게시물을 무상으로 이용(복제·전송·전시 등)할 수 있도록 비독점적 이용권을 부여합니다.'},
  {'type': 'body', 'content': '3. 회사는 게시물이 타인의 권리를 침해한다고 판단되는 경우 사전통지 없이 삭제·이용제한 할 수 있습니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제10조 (면책조항)'},
  {'type': 'body', 'content': '1. 회사는 천재지변, 통신두절, 제3자 서비스 장애 등 회사의 고의·중과실이 아닌 사유로 인한 서비스 중단·데이터 손실에 대해 책임을 지지 않습니다.'},
  {'type': 'body', 'content': '2. 이용자가 공유한 공개 경로를 통해 발생한 이용자 간 분쟁·피해는 해당 이용자 책임입니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제11조 (계약해지·이용제한)'},
  {'type': 'body', 'content': '1. 이용자는 계정을 삭제하거나 서비스 이용을 중단할 수 있습니다.'},
  {'type': 'body', 'content': '2. 회사는 약관 위반·부정 이용 등 최소한의 절차를 거쳐 이용제한·계정정지·삭제할 수 있습니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제12조 (개인정보 보호)'},
  {'type': 'body', 'content': '개인정보의 수집·이용·보유 관련 사항은 별도의 “개인정보 처리방침”을 따릅니다.'},

  {'type': 'subtitle', 'content': '제13조 (아동 보호 및 안전 정책)'},
  {'type': 'body', 'content': '1. 회사는 아동의 안전을 최우선으로 하며, 아동 성적 학대 및 착취(CSAE, Child Sexual Abuse and Exploitation)를 명시적으로 금지합니다.'},
  {'type': 'body', 'content': '2. 이용자는 아동을 대상으로 한 불법적 행위나 콘텐츠(아동 성착취물, 성적 학대 표현물 등)를 업로드하거나 공유해서는 안 됩니다.'},
  {'type': 'body', 'content': '3. 회사는 아동 보호와 관련된 법령 및 Google Play의 아동 안전 표준 정책을 준수합니다.'},
  {'type': 'body', 'content': '4. 이용자가 아동 보호 정책을 위반한 경우, 회사는 즉시 콘텐츠 삭제, 계정 정지 또는 수사기관 신고 등의 조치를 취할 수 있습니다.'},
  {'type': 'body', 'content': '5. 회사는 아동 안전 및 학대 예방을 위한 담당자를 지정하며, 이용자는 아래 연락처를 통해 관련 신고나 문의를 할 수 있습니다.'},
  {'type': 'space', 'content': ''},

];

final List<Map<String, String>> privacyPolicy = [
  {'type': 'title', 'content': '개인정보 처리방침'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제1조 (수집하는 개인정보 항목)'},
  {'type': 'body', 'content': '1. 필수 수집 항목: 회원가입 시 이메일(또는 휴대전화), 비밀번호(암호화 저장), 닉네임(선택)'},
  {'type': 'body', 'content': '2. 위치정보: 서비스 제공을 위해 실시간·주기적 GPS 위치(위도·경도), 이동경로 데이터(시작시간·종료시간·속도 등)를 수집합니다.'},
  {'type': 'body', 'content': '3. 선택 수집 항목: 프로필 사진, 활동 통계(평균 속도, 주행 거리 등), 업로드 사진·코멘트 등.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제2조 (수집 방법)'},
  {'type': 'body', 'content': '앱 설치 시 권한 요청, 회원가입·프로필 입력, 서비스 이용 중 자동 수집(GPS·센서), 사용자가 업로드한 콘텐츠 수집.'},
  {'type': 'body', 'content': '서비스 품질 향상 및 이용자 편의를 위해 백그라운드에서도 위치정보가 수집될 수 있으며, 명시적 동의 및 단말기 권한 허용이 필요합니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제3조 (수집 목적)'},
  {'type': 'body', 'content': '• 서비스 제공 및 개선(경로 추적·저장·공유, 통계 제공)'},
  {'type': 'body', 'content': '• 백그라운드 위치정보 수집: 실시간 주행 기록 유지, 안전 알림, 이동 통계 제공 등'},
  {'type': 'body', 'content': '• 이용자 식별 및 계정관리'},
  {'type': 'body', 'content': '• 고객지원 및 불만처리'},
  {'type': 'body', 'content': '• 마케팅 및 맞춤형 서비스 제공(선택 동의 시)'},
  {'type': 'body', 'content': '• 법적 의무 이행'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제4조 (처리 및 보유 기간)'},
  {'type': 'body', 'content': '• 회원정보: 회원탈퇴 시까지(탈퇴 후 관련법령에 따라 일부 정보는 보존)'},
  {'type': 'body', 'content': '• 위치정보(경로 데이터): 기본 보관 기간은 3년. 이용자가 삭제 요청 시 지체없이 삭제 처리합니다.'},
  {'type': 'body', 'content': '• 보존이 필요한 경우(분쟁·법령상 의무 등) 해당 사유 소멸 시까지 보관합니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제5조 (위치정보의 이용·제공 동의 및 선택권)'},
  {'type': 'body', 'content': '1. 위치정보 수집은 서비스 제공에 필수적이므로, 이용자는 앱 권한 허용을 통해 동의합니다. 권한 해제 시 추적·공유 기능이 제한됩니다.'},
  {'type': 'body', 'content': '2. 이용자는 언제든지 위치정보 수집·이용을 중단(앱 권한 해제)하거나, 저장된 경로를 삭제할 수 있습니다.'},
  {'type': 'body', 'content': '3. 백그라운드 위치 수집은 서비스 지속 제공을 위해 사용되며, 최초 실행 시 별도의 동의 절차를 통해 허용됩니다. 사용자는 단말기 설정 또는 앱 내 설정을 통해 철회할 수 있습니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제6조 (제3자 제공)'},
  {'type': 'body', 'content': '1. 회사는 이용자의 동의 없이 원칙적으로 개인정보를 제3자에게 제공하지 않습니다.'},
  {'type': 'body', 'content': '2. 단, 이용자가 공개설정한 경로 등 공개 콘텐츠는 타 이용자 또는 제휴 서비스에 노출될 수 있습니다.'},
  {'type': 'body', 'content': '3. 법령에 따른 요청 또는 서비스 제공을 위해 필요한 경우에는 관련 법령에 따라 제공할 수 있습니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제8조 (정보주체의 권리와 행사방법)'},
  {'type': 'body', 'content': '이용자는 개인정보 열람·정정·삭제·처리정지·동의철회 등을 요청할 수 있으며, 회사는 지체 없이 처리합니다. 권리행사는 앱 내 설정 또는 고객센터로 요청 가능합니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제9조 (안전성 확보조치)'},
  {'type': 'body', 'content': '기술적 조치: 개인정보 암호화, 접근통제, 침입차단시스템 등'},
  {'type': 'body', 'content': '관리적 조치: 내부관리계획 수립·시행, 최소 권한 원칙 적용 등'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제10조 (아동의 개인정보 보호)'},
  {'type': 'body', 'content': '1. 회사는 만 14세 미만 아동의 개인정보를 법정대리인의 동의 없이 수집하거나 이용하지 않습니다.'},
  {'type': 'body', 'content': '2. 아동 관련 콘텐츠 및 데이터는 아동의 안전을 침해하지 않는 범위 내에서만 처리되며, 모든 절차는 관련 법령 및 Google Play 아동 안전 표준 정책을 준수합니다.'},
  {'type': 'body', 'content': '3. 아동의 개인정보가 포함된 불법 콘텐츠(예: 아동 성착취물, CSAM 등)는 즉시 삭제되며, 관련 기관에 신고될 수 있습니다.'},
  {'type': 'body', 'content': '4. 아동 개인정보 보호 관련 문의는 다음 연락처로 가능합니다.'},
  {'type': 'space', 'content': ''},

  {'type': 'subtitle', 'content': '제11조 (개인정보 보호책임자 및 아동 안전 담당자 및 연락처)'},
  {'type': 'body', 'content': '• 개인정보 보호책임자: 김준화'},
  {'type': 'body', 'content': '• 연락처: nuclbackki1@worldpedal.com'},
  {'type': 'body', 'content': '• 우편주소: 35398'},
];
