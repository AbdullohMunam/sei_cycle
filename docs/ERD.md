# ERD SeiCycle

## Deskripsi

SeiCycle adalah aplikasi operasional Kebun Sei untuk mendukung pencatatan, monitoring, analisis, edukasi, dan pengambilan keputusan pada sistem pertanian dan peternakan terintegrasi berbasis ekonomi sirkular.

ERD ini digunakan sebagai rancangan konseptual database. Implementasi database utama menggunakan Firebase Authentication, Cloud Firestore, Firebase Storage, dan Firebase Cloud Messaging.

## Entitas Utama

1. Users
2. User Devices
3. Farm Modules
4. Production Cycles
5. Operational Logs
6. Production Results
7. Inventory Items
8. Inventory Transactions
9. Stock Alerts
10. Schedules
11. Notifications
12. Education Materials
13. Finance Transactions
14. Circular Flows
15. Reports
16. AI Recommendations

## Catatan

Tabel `AI_RECOMMENDATIONS` merupakan fitur tahap lanjutan. Fitur ini digunakan untuk prediksi panen, evaluasi produktivitas, dan rekomendasi berbasis data setelah modul utama stabil.

## Diagram ERD

```mermaid
erDiagram
    USERS ||--o{ USER_DEVICES : owns
    USERS ||--o{ OPERATIONAL_LOGS : creates
    USERS ||--o{ INVENTORY_TRANSACTIONS : records
    USERS ||--o{ SCHEDULES : creates
    USERS ||--o{ NOTIFICATIONS : receives
    USERS ||--o{ EDUCATION_MATERIALS : publishes
    USERS ||--o{ FINANCE_TRANSACTIONS : records
    USERS ||--o{ REPORTS : generates
    USERS ||--o{ AI_RECOMMENDATIONS : receives

    FARM_MODULES ||--o{ PRODUCTION_CYCLES : has
    FARM_MODULES ||--o{ INVENTORY_ITEMS : uses
    FARM_MODULES ||--o{ SCHEDULES : related_to
    FARM_MODULES ||--o{ AI_RECOMMENDATIONS : analyzed_by

    FARM_MODULES ||--o{ CIRCULAR_FLOWS : source
    FARM_MODULES ||--o{ CIRCULAR_FLOWS : destination

    PRODUCTION_CYCLES ||--o{ OPERATIONAL_LOGS : contains
    PRODUCTION_CYCLES ||--o{ PRODUCTION_RESULTS : produces
    PRODUCTION_CYCLES ||--o{ SCHEDULES : scheduled_for
    PRODUCTION_CYCLES ||--o{ AI_RECOMMENDATIONS : evaluated_by

    INVENTORY_ITEMS ||--o{ INVENTORY_TRANSACTIONS : has
    INVENTORY_ITEMS ||--o{ STOCK_ALERTS : triggers

    SCHEDULES ||--o{ NOTIFICATIONS : generates

    USERS {
        string user_id PK
        string name
        string email
        string role
        string photo_url
        boolean is_active
        datetime created_at
        datetime updated_at
    }

    USER_DEVICES {
        string device_id PK
        string user_id FK
        string fcm_token
        string platform
        string device_name
        datetime last_active_at
        datetime created_at
    }

    FARM_MODULES {
        string module_id PK
        string module_name
        string module_type
        string description
        boolean is_active
        datetime created_at
    }

    PRODUCTION_CYCLES {
        string cycle_id PK
        string module_id FK
        string cycle_name
        string location
        date start_date
        date end_date
        string status
        string notes
        datetime created_at
    }

    OPERATIONAL_LOGS {
        string log_id PK
        string cycle_id FK
        string user_id FK
        string activity_type
        date activity_date
        string description
        number quantity
        string unit
        string photo_url
        datetime created_at
    }

    PRODUCTION_RESULTS {
        string result_id PK
        string cycle_id FK
        date harvest_date
        string product_name
        number quantity
        string unit
        string quality_status
        string notes
    }

    INVENTORY_ITEMS {
        string item_id PK
        string module_id FK
        string item_name
        string category
        number current_stock
        string unit
        number minimum_stock
        string location
        datetime created_at
    }

    INVENTORY_TRANSACTIONS {
        string transaction_id PK
        string item_id FK
        string user_id FK
        string transaction_type
        number quantity
        string unit
        string notes
        datetime transaction_date
    }

    STOCK_ALERTS {
        string alert_id PK
        string item_id FK
        string user_id FK
        string alert_type
        string message
        boolean is_read
        datetime created_at
    }

    SCHEDULES {
        string schedule_id PK
        string cycle_id FK
        string module_id FK
        string user_id FK
        string title
        string activity_type
        datetime schedule_date
        string status
        string notes
    }

    NOTIFICATIONS {
        string notification_id PK
        string schedule_id FK
        string user_id FK
        string title
        string message
        string type
        boolean is_read
        datetime created_at
    }

    EDUCATION_MATERIALS {
        string material_id PK
        string user_id FK
        string title
        string type
        string content
        string file_url
        string category
        datetime created_at
    }

    FINANCE_TRANSACTIONS {
        string finance_id PK
        string user_id FK
        string transaction_type
        string category
        string description
        number amount
        date transaction_date
        datetime created_at
    }

    CIRCULAR_FLOWS {
        string flow_id PK
        string source_module_id FK
        string destination_module_id FK
        string material_name
        number quantity
        string unit
        date flow_date
        string notes
    }

    REPORTS {
        string report_id PK
        string user_id FK
        string report_type
        string file_url
        date start_date
        date end_date
        datetime generated_at
    }

    AI_RECOMMENDATIONS {
        string recommendation_id PK
        string cycle_id FK
        string module_id FK
        string user_id FK
        string recommendation_type
        string title
        string description
        string source_data
        number prediction_value
        number confidence_score
        string suggested_action
        string status
        string implementation_stage
        string notes
        datetime created_at
    }