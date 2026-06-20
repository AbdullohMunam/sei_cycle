# ERD MVP SeiCycle

Firestore bersifat document database, sehingga diagram berikut menunjukkan
relasi logis melalui UID dan `module_id`, bukan foreign key database.

```mermaid
erDiagram
    USERS ||--o{ LOGBOOKS : creates
    USERS ||--o{ INVENTORY_ITEMS : creates
    USERS ||--o{ SCHEDULES : creates
    USERS ||--o{ FINANCE_RECORDS : creates
    FARM_MODULES ||--o{ LOGBOOKS : categorizes
    FARM_MODULES ||--o{ SCHEDULES : categorizes

    USERS {
        string uid PK
        string name
        string email
        string photo_url
        string role
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    FARM_MODULES {
        string module_id PK
        string module_name
        string module_type
        string description
        string icon
        string color
        boolean is_active
    }

    LOGBOOKS {
        string id PK
        string module_id
        string created_by
        string activity_type
        timestamp activity_date
        number quantity
        string unit
        string condition
        boolean is_deleted
    }

    INVENTORY_ITEMS {
        string id PK
        string created_by
        string name
        string category
        string unit
        number current_stock
        number min_stock
        boolean is_low_stock
    }

    SCHEDULES {
        string id PK
        string module_id
        string created_by
        string title
        string schedule_type
        timestamp scheduled_at
        string status
    }

    EDUCATION_CONTENTS {
        string id PK
        string title
        string type
        string content
        string external_url
        boolean is_published
    }

    FINANCE_RECORDS {
        string id PK
        string created_by
        string type
        string category
        number amount
        timestamp date
    }
```

AI recommendation, laporan PDF/Excel, Storage upload, dan backend API berada di
luar scope MVP.
