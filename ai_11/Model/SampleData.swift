//
//  SampleData.swift
//  ai_11
//
//  Created by JunHyuk on 2017. 12. 7..
//  Copyright © 2017년 com.JunHyuk. All rights reserved.
//

import Foundation

struct Sample {             //구조체로 데이터 구성
    let title: String
    let description: String
    let image: String
}

struct SampleData {         // 구조체 상수 배열선언.
    let samples = [
        Sample(title: "Photo Object Detection", description: "불러온 이미지에 있는 사물 인식", image: "ic_photo"),
        Sample(title: "Real Time Object Detection", description: "실시간으로 카메라에 보이는 사물 인식", image: "ic_camera"),
        Sample(title: "Facial Analysis", description: "사람 얼굴로부터 나이, 성별, 감정 추측", image: "ic_emotion")
    ]
}
