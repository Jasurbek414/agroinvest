CREATE TABLE regions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

-- Seed defaults
INSERT INTO regions (name) VALUES
('Toshkent viloyati'),
('Toshkent shahri'),
('Samarqand viloyati'),
('Farg''ona viloyati'),
('Andijon viloyati'),
('Namangan viloyati'),
('Buxoro viloyati'),
('Xorazm viloyati'),
('Qashqadaryo viloyati'),
('Surxondaryo viloyati'),
('Jizzax viloyati'),
('Sirdaryo viloyati'),
('Navoiy viloyati'),
('Qoraqalpog''iston Respublikasi')
ON CONFLICT (name) DO NOTHING;
