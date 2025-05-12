import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock the Clarity environment
const mockClarity = {
  contracts: {
    'specialty-certification': {
      functions: {
        'add-specialty': vi.fn(),
        'get-specialty': vi.fn(),
        'certify-provider': vi.fn(),
        'get-provider-specialty': vi.fn(),
        'revoke-certification': vi.fn(),
        'update-certification': vi.fn(),
        'transfer-admin': vi.fn()
      }
    }
  },
  tx: {
    sender: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'
  }
};

// Mock implementation for add-specialty
mockClarity.contracts['specialty-certification'].functions['add-specialty'].mockImplementation(
    (specialtyId, name) => {
      return { success: true, value: true };
    }
);

// Mock implementation for get-specialty
mockClarity.contracts['specialty-certification'].functions['get-specialty'].mockImplementation(
    (specialtyId) => {
      if (specialtyId === 'CARDIOLOGY') {
        return {
          success: true,
          value: {
            name: 'Cardiology'
          }
        };
      }
      return { success: true, value: null };
    }
);

// Mock implementation for certify-provider
mockClarity.contracts['specialty-certification'].functions['certify-provider'].mockImplementation(
    (providerId, specialtyId, expiryDate, certificationAuthority) => {
      if (specialtyId === 'CARDIOLOGY') {
        return { success: true, value: true };
      }
      return { success: false, error: 404 };
    }
);

describe('Specialty Certification Contract', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });
  
  it('should add a new specialty', () => {
    const result = mockClarity.contracts['specialty-certification'].functions['add-specialty'](
        'NEUROLOGY', 'Neurology'
    );
    
    expect(result.success).toBe(true);
    expect(mockClarity.contracts['specialty-certification'].functions['add-specialty']).toHaveBeenCalledWith(
        'NEUROLOGY', 'Neurology'
    );
  });
  
  it('should get specialty information', () => {
    const result = mockClarity.contracts['specialty-certification'].functions['get-specialty']('CARDIOLOGY');
    
    expect(result.success).toBe(true);
    expect(result.value).toEqual({
      name: 'Cardiology'
    });
  });
  
  it('should certify a provider in a specialty', () => {
    const result = mockClarity.contracts['specialty-certification'].functions['certify-provider'](
        'PROVIDER1', 'CARDIOLOGY', 200000, 'American Board of Cardiology'
    );
    
    expect(result.success).toBe(true);
    expect(mockClarity.contracts['specialty-certification'].functions['certify-provider']).toHaveBeenCalledWith(
        'PROVIDER1', 'CARDIOLOGY', 200000, 'American Board of Cardiology'
    );
  });
  
  it('should fail to certify a provider in a non-existent specialty', () => {
    const result = mockClarity.contracts['specialty-certification'].functions['certify-provider'](
        'PROVIDER1', 'NONEXISTENT', 200000, 'Unknown Board'
    );
    
    expect(result.success).toBe(false);
    expect(result.error).toBe(404);
  });
});
