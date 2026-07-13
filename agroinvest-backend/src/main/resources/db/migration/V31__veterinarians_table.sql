CREATE TABLE veterinarians (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    license_no VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(50),
    specialty VARCHAR(150),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT now()
);
