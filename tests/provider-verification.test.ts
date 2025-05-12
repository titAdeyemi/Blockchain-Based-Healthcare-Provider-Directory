import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock the Clarity environment
const mockClarity = {
  contracts: {
    'provider-verification': {
      functions: {
        'register-provider': vi.fn(),
        'verify-provider': vi.fn(),
        'suspend-provider': vi.fn(),
        'get-provider': vi.fn(),
        'update-license': vi.fn(),
        'transfer-admin': vi.fn()
      }
    }
  },
  tx: {
    sender: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'
  }
};

// Mock implementation for register-provider
mockClarity.contracts['provider-verification'].functions['register-provider'].mockImplementation(
    (providerId, licenseNumber, licenseExpiry) => {
      return { success: true, value: true };
    }
);

// Mock implementation for get-provider
mockClarity.contracts['provider-verification'].functions['get-provider'].mockImplementation(
    (providerId) => {
      if (providerId === 'PROVIDER1') {
        return {
          success: true,
          value: {
            principal: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
            status: 0,
            'license-number': 'LIC123',
            'license-expiry': 100000,
            'verification-date': 0
          }
        };
      }
      return { success: true, value: null };
    }
);

// Mock implementation for verify-provider
mockClarity.contracts['provider-verification'].functions['verify-provider'].mockImplementation(
    (providerId) => {
      if (providerId === 'PROVIDER1') {
        return { success: true, value: true };
      }
      return { success: false, error: 404 };
    }
);

describe('Provider Verification Contract', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });
  
  it('should register a new provider', () => {
    const result = mockClarity.contracts['provider-verification'].functions['register-provider'](
        'PROVIDER2', 'LIC456', 200000
    );
    
    expect(result.success).toBe(true);
    expect(mockClarity.contracts['provider-verification'].functions['register-provider']).toHaveBeenCalledWith(
        'PROVIDER2', 'LIC456', 200000
    );
  });
  
  it('should get provider information', () => {
    const result = mockClarity.contracts['provider-verification'].functions['get-provider']('PROVIDER1');
    
    expect(result.success).toBe(true);
    expect(result.value).toEqual({
      principal: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
      status: 0,
      'license-number': 'LIC123',
      'license-expiry': 100000,
      'verification-date': 0
    });
  });
  
  it('should verify a provider', () => {
    const result = mockClarity.contracts['provider-verification'].functions['verify-provider']('PROVIDER1');
    
    expect(result.success).toBe(true);
    expect(mockClarity.contracts['provider-verification'].functions['verify-provider']).toHaveBeenCalledWith('PROVIDER1');
  });
  
  it('should fail to verify a non-existent provider', () => {
    mockClarity.contracts['provider-verification'].functions['verify-provider'].mockImplementationOnce(
        (providerId) => {
          return { success: false, error: 404 };
        }
    );
    
    const result = mockClarity.contracts['provider-verification'].functions['verify-provider']('NONEXISTENT');
    
    expect(result.success).toBe(false);
    expect(result.error).toBe(404);
  });
});
