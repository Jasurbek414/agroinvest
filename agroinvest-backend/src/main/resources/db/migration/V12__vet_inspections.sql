-- Veterinary inspection documents: the farmer uploads the vet's conclusion
-- (PDF/photo) after a check-up; staff verifies it. VERIFIED inspections are
-- shown publicly on the project as a trust signal.

CREATE TABLE vet_inspections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id),
    uploaded_by UUID NOT NULL REFERENCES users(id),
    vet_name VARCHAR(200) NOT NULL,
    vet_license_no VARCHAR(100),
    inspection_date DATE NOT NULL,
    document_urls JSONB DEFAULT '[]',
    conclusion TEXT,
    health_status VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMP,
    admin_comment VARCHAR(500),
    created_at TIMESTAMP DEFAULT now(),
    CONSTRAINT chk_vet_health_status CHECK (health_status IN ('HEALTHY', 'TREATED', 'QUARANTINE', 'SICK')),
    CONSTRAINT chk_vet_status CHECK (status IN ('PENDING', 'VERIFIED', 'REJECTED'))
);

CREATE INDEX idx_vet_inspections_project ON vet_inspections(project_id, inspection_date DESC);
CREATE INDEX idx_vet_inspections_pending ON vet_inspections(status) WHERE status = 'PENDING';
