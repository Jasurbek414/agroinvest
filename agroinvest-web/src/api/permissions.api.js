import api from './axios';

export const listPermissions = () => api.get('/superadmin/permissions');

export const createPermission = (code, description) =>
  api.post('/superadmin/permissions', { code, description });

export const getRolePermissions = (role) => api.get(`/superadmin/permissions/roles/${role}`);

export const grantToRole = (role, permissionCode) =>
  api.post(`/superadmin/permissions/roles/${role}/grant`, {}, { params: { permissionCode } });

export const revokeFromRole = (role, permissionCode) =>
  api.post(`/superadmin/permissions/roles/${role}/revoke`, {}, { params: { permissionCode } });

export const listCustomRoles = () => api.get('/superadmin/permissions/custom-roles');

export const createCustomRole = (name, description) =>
  api.post('/superadmin/permissions/custom-roles', { name, description });

export const addPermissionToCustomRole = (customRoleId, permissionCode) =>
  api.post(`/superadmin/permissions/custom-roles/${customRoleId}/permissions`, {}, { params: { permissionCode } });

export const assignCustomRoleToUser = (customRoleId, userId) =>
  api.post(`/superadmin/permissions/custom-roles/${customRoleId}/users/${userId}`);

export const unassignCustomRoleFromUser = (customRoleId, userId) =>
  api.delete(`/superadmin/permissions/custom-roles/${customRoleId}/users/${userId}`);
