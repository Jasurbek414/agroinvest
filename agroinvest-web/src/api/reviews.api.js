import api from './axios';

export const getFarmerReviews = (farmerId, page = 0, size = 10) => {
  return api.get(`/reviews/farmer/${farmerId}`, { params: { page, size } });
};

export const createReview = (investmentId, rating, comment) => {
  return api.post('/reviews', { investmentId, rating, comment });
};
