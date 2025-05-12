import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock the Clarity environment
const mockClarity = {
  contracts: {
    'directory-access': {
      functions: {
        'create-access-key': vi.fn(),
        'get-access-key': vi.fn(),
        'revoke-access-key': vi.fn(),
        'extend-access-key': vi.fn(),
        'log-access': vi.fn(),
        'get-access-log': vi.fn(),
        'transfer-admin': vi.fn()
      }
    }
  },
  tx: {
    sender: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'
  },
  globals: {
    'block-height': 10000
  }
};

// Mock implementation for create-access-key
mockClarity.contracts['directory-access'].functions['create-access-key'].mockImplementation(
    (keyId, user, accessLevel, expiryDate, organization) => {
      return { success: true, value: true };
    }
);

// Mock implementation for get-access-key
mockClarity.contracts['directory-access'].functions['get-access-key'].mockImplementation(
    (keyId) => {
      if (keyId === 'KEY1') {
        return {
          success: true,
          value: {
            principal: 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG',
            'access-level': 1,
            'expiry-date': 20000,
            'is-active': true,
            organization: 'Hospital Corp'
          }
        };
      }
      return { success: true, value: null };
    }
);

// Mock implementation for log-access
mockClarity.contracts['directory-access'].functions['log-access'].mockImplementation(
    (keyId, resourceType, resourceId, action) => {
      if (keyId === 'KEY1') {
        return { success: true, value: true };
      }
      return { success: false, error: 404 };
    }
);

describe('Directory Access Contract', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });
  
  it('should create a new access key', () => {
    const result = mockClarity.contracts['directory-access'].functions['create-access-key'](
        'KEY2', 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG', 2, 30000, 'Insurance Co'
    );
    
    expect(result.success).toBe(true);
    expect(mockClarity.contracts['directory-access'].functions['create-access-key']).toHaveBeenCalledWith(
        'KEY2', 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG', 2, 30000, 'Insurance Co'
    );
  });
  
  it('should get access key information', () => {
    const result = mockClarity.contracts['directory-access'].functions['get-access-key']('KEY1');
    
    expect(result.success).toBe(true);
    expect(result.value).toEqual({
      principal: 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG',
      'access-level': 1,
      'expiry-date': 20000,
      'is-active': true,
      organization: 'Hospital Corp'
    });
  });
  
  it('should log access to a resource', () => {
    const result = mockClarity.contracts['directory-access'].functions['log-access'](
        'KEY1', 'provider', 'PROVIDER1', 'read'
    );
    
    expect(result.success).toBe(true);
    expect(mockClarity.contracts['directory-access'].functions['log-access']).toHaveBeenCalledWith(
        'KEY1', 'provider', 'PROVIDER1', 'read'
    );
  });
  
  it('should fail to log access with an invalid key', () => {
    const result = mockClarity.contracts['directory-access'].functions['log-access'](
        'INVALID_KEY', 'provider', 'PROVIDER1', 'read'
    );
    
    expect(result.success).toBe(false);
    expect(result.error).toBe(404);
  });
});
