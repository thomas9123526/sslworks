# vLearn2 (VFLS) — Specification Library

Documentation set for the vLearn2 project (`C:\project\vLearn2`). Every
document is provided in English (`_en`) and Korean (`_ko`), each as
Markdown (`.md`) and Microsoft Word (`.docx`).

All documents are derived from a read-only inspection of the vLearn2
codebase; that project is not modified.

## Structure

```
Specification/
├── 00_Core/
│   ├── Requirements_Specification/      소프트웨어 요구사항 명세서
│   ├── System_Design_Specification/     시스템 설계 명세서
│   └── Testing_Specification/           테스트 명세서
├── 01_Engineering/
│   ├── API_Reference/                   API 레퍼런스
│   ├── Database_Design_Document/        데이터베이스 설계 문서
│   ├── Security_Specification/          보안 명세서 및 위협 모델
│   ├── Architecture_Decision_Records/   아키텍처 결정 기록
│   ├── Deployment_Operations_Runbook/   배포 및 운영 런북
│   └── Interface_Control_Document/      인터페이스 통제 문서
├── 02_Management/
│   ├── Product_Requirements_Document/   제품 요구사항 문서
│   ├── Requirements_Traceability_Matrix/ 요구사항 추적 매트릭스
│   └── Project_Risk_Management_Plan/    프로젝트 및 리스크 관리 계획
├── 03_User_Documentation/
│   ├── End_User_Manual/                 사용자 매뉴얼
│   ├── Administrator_Guide/             관리자 가이드
│   ├── Developer_Setup_Guide/           개발자 설정 가이드
│   └── Release_Notes/                   릴리스 노트
└── 04_Quality_Assurance/
    ├── Detailed_Test_Cases/             상세 테스트 케이스
    ├── Test_Summary_Report/             테스트 요약 보고서
    └── UAT_Plan/                        사용자 인수 테스트 계획
```

## Document index

| # | Document | Folder |
|---|----------|--------|
| 1 | Requirements Specification (SRS) | `00_Core/Requirements_Specification` |
| 2 | System Design Specification (SDS) | `00_Core/System_Design_Specification` |
| 3 | Testing Specification | `00_Core/Testing_Specification` |
| 4 | API Reference | `01_Engineering/API_Reference` |
| 5 | Database Design Document | `01_Engineering/Database_Design_Document` |
| 6 | Security Specification & Threat Model | `01_Engineering/Security_Specification` |
| 7 | Architecture Decision Records | `01_Engineering/Architecture_Decision_Records` |
| 8 | Deployment & Operations Runbook | `01_Engineering/Deployment_Operations_Runbook` |
| 9 | Interface Control Document | `01_Engineering/Interface_Control_Document` |
| 10 | Product Requirements Document (PRD) | `02_Management/Product_Requirements_Document` |
| 11 | Requirements Traceability Matrix | `02_Management/Requirements_Traceability_Matrix` |
| 12 | Project & Risk Management Plan | `02_Management/Project_Risk_Management_Plan` |
| 13 | End-User Manual | `03_User_Documentation/End_User_Manual` |
| 14 | Administrator Guide | `03_User_Documentation/Administrator_Guide` |
| 15 | Developer Setup Guide | `03_User_Documentation/Developer_Setup_Guide` |
| 16 | Release Notes | `03_User_Documentation/Release_Notes` |
| 17 | Detailed Test Cases | `04_Quality_Assurance/Detailed_Test_Cases` |
| 18 | Test Summary Report | `04_Quality_Assurance/Test_Summary_Report` |
| 19 | UAT Plan | `04_Quality_Assurance/UAT_Plan` |

## Notes

- The **Test Summary Report** is a point-in-time baseline reflecting
  the current automated-test state; it should be regenerated after each
  executed test cycle.
- **Release Notes** documents the v1.0.0 baseline derived from the
  current feature set.
- Specifications are reconstructed from the implemented system and
  serve as a maintenance and change-control baseline.
