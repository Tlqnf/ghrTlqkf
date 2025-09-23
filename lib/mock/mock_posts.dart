final List<Map<String, dynamic>> mockPosts = [
  {
    "id": 1,
    "title": "첫 번째 게시물",
    "content": "이것은 첫 번째 목업 게시물의 내용입니다. UI 테스트를 위해 사용됩니다.",
    "like_count": 15,
    "read_count": 120,
    "comment_count": 5,
    "user_id": 101,
    "report_id": 201,
    "created_at": "2025-09-22T10:00:00.000Z",
    "images": [
      "assets/image_mock.png",
      "assets/image_mock.png"
    ],
    "hash_tag": [
      "테스트",
      "목업",
      "UI"
    ],
    "public": true,
    "map_image_url": "assets/map.png",
    "speed": 25.5,
    "distance": 42.195,
    "time": "02:30:45"
  },
  {
    "id": 2,
    "title": "두 번째 게시물: 비공개",
    "content": "이것은 비공개 게시물입니다. 다른 사용자에게 보이지 않아야 합니다.",
    "like_count": 2,
    "read_count": 10,
    "comment_count": 1,
    "user_id": 102,
    "report_id": 202,
    "created_at": "2025-09-21T15:30:00.000Z",
    "images": [],
    "hash_tag": [
      "비공개",
      "테스트"
    ],
    "public": false,
    "map_image_url": "assets/map.png",
    "speed": 22.0,
    "distance": 15.0,
    "time": "00:45:10"
  },
  {
    "id": 3,
    "title": "세 번째 게시물: 이미지 없음",
    "content": "이 게시물에는 이미지가 없습니다. 이미지가 없을 때 UI가 어떻게 보이는지 테스트합니다.",
    "like_count": 0,
    "read_count": 5,
    "comment_count": 0,
    "user_id": 103,
    "report_id": 203,
    "created_at": "2025-09-20T18:00:00.000Z",
    "images": [],
    "hash_tag": [
      "이미지없음"
    ],
    "public": true,
    "map_image_url": "assets/map.png",
    "speed": 18.7,
    "distance": 5.2,
    "time": "00:15:30"
  },
  {
    "id": 4,
    "title": "네 번째 게시물: 긴 제목과 내용 테스트입니다. 제목이 길어질 때 어떻게 보이는지 확인하기 위한 목적으로 작성되었습니다.",
    "content": "내용도 길게 작성해 봅니다. 여러 줄에 걸쳐 내용이 표시될 때 UI가 깨지지 않는지 확인해야 합니다. 특히 모바일 화면에서는 텍스트가 화면을 벗어나는 경우가 많으므로, 이를 잘 처리해야 합니다. word break, overflow ellipsis 등의 처리가 잘 되어 있는지 꼼꼼히 확인해 보세요.",
    "like_count": 100,
    "read_count": 1000,
    "comment_count": 50,
    "user_id": 101,
    "report_id": 204,
    "created_at": "2025-09-19T12:00:00.000Z",
    "images": [
      "assets/image_mock.png"
    ],
    "hash_tag": [
      "긴글",
      "UI테스트",
      "overflow"
    ],
    "public": true,
    "map_image_url": "assets/map.png",
    "speed": 20.1,
    "distance": 21.1,
    "time": "01:05:00"
  }
];
