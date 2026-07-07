-- TZ 3.9 (F-9.1/9.2): investor -> farmer reviews. One review per investment
-- (UNIQUE) so a review can only be left against a real, paid-out investment -
-- prevents fake/unlimited reviews for the same stake.
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id),
    investment_id UUID NOT NULL UNIQUE REFERENCES investments(id),
    investor_id UUID NOT NULL REFERENCES users(id),
    farmer_id UUID NOT NULL REFERENCES users(id),
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_reviews_farmer_id ON reviews(farmer_id);
