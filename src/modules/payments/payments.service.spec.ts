import { Test, TestingModule } from '@nestjs/testing';
import { PaymentsService } from './payments.service';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsGateway } from '../notifications/notifications.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { PLATFORM_CONSTANTS } from '../../common/constants';

describe('PaymentsService - Tarheel Escrow, 15% VAT, 10% Commission & Bank Payout', () => {
  let service: PaymentsService;
  let prisma: any;

  beforeEach(async () => {
    const mockPrisma = {
      tripContract: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      escrowPayment: {
        create: jest.fn(),
        update: jest.fn(),
      },
      walletTransaction: {
        create: jest.fn(),
      },
      tripRequest: {
        update: jest.fn(),
      },
      driverProfile: {
        update: jest.fn(),
      },
      $transaction: jest.fn((callback) => callback(mockPrisma)),
    };

    const mockGateway = {
      notifyContractCompleted: jest.fn(),
    };

    const mockNotificationsService = {
      createNotification: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PaymentsService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: NotificationsGateway, useValue: mockGateway },
        { provide: NotificationsService, useValue: mockNotificationsService },
      ],
    }).compile();

    service = module.get<PaymentsService>(PaymentsService);
    prisma = module.get(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should verify 15% VAT and 10% Platform Commission calculations', async () => {
    const baseOfferPrice = 1000;
    const vatAmount = (baseOfferPrice * PLATFORM_CONSTANTS.VAT_PERCENTAGE) / 100; // 15%
    const totalPaidByClient = baseOfferPrice + vatAmount; // 1150

    const platformCommission = (baseOfferPrice * PLATFORM_CONSTANTS.COMMISSION_PERCENTAGE) / 100; // 100
    const driverEarnings = baseOfferPrice - platformCommission; // 900

    expect(vatAmount).toBe(150);
    expect(totalPaidByClient).toBe(1150);
    expect(platformCommission).toBe(100);
    expect(driverEarnings).toBe(900);
  });

  it('should correctly transfer 90% funds to driver bank account upon review & contract completion', async () => {
    const contractId = 'contract-123';
    const clientId = 'client-456';
    const mockContract = {
      id: contractId,
      clientId,
      driverProfileId: 'driver-prof-789',
      baseAmount: 2000,
      vatRate: 15,
      vatAmount: 300,
      totalPaidByClient: 2300,
      platformCommissionRate: 10,
      platformCommissionAmount: 200,
      driverEarnings: 1800,
      escrowStatus: 'HELD_IN_ESCROW',
      contractStatus: 'ACTIVE',
      tripRequestId: 'trip-999',
      driverBankIban: 'SA0380000000608010167519',
      driverBankName: 'مصرف الراجحي',
      driverProfile: {
        id: 'driver-prof-789',
        userId: 'driver-user-888',
        user: { id: 'driver-user-888' },
        iban: 'SA0380000000608010167519',
        bankName: 'مصرف الراجحي',
        walletBalance: 500,
        pendingEscrowBalance: 1800,
      },
      client: { id: clientId },
      tripRequest: { id: 'trip-999' },
      escrowPayment: { id: 'escrow-111' },
    };

    prisma.tripContract.findUnique.mockResolvedValue(mockContract);
    prisma.driverProfile.update.mockResolvedValue({
      ...mockContract.driverProfile,
      walletBalance: 2300, // 500 + 1800
      pendingEscrowBalance: 0,
    });
    prisma.tripContract.update.mockResolvedValue({
      ...mockContract,
      contractStatus: 'COMPLETED',
      escrowStatus: 'RELEASED_TO_DRIVER_BANK',
    });

    const result = await service.completeContractAndReleaseFunds(contractId, clientId);

    expect(result.contractStatus).toBe('COMPLETED');
    expect(result.escrowStatus).toBe('RELEASED_TO_DRIVER_BANK');
    expect(result.financialSummary.baseTripPrice).toBe(2000);
    expect(result.financialSummary.vat15PercentCollected).toBe(300);
    expect(result.financialSummary.totalPaidByClient).toBe(2300);
    expect(result.financialSummary.platformCommission10Percent).toBe(200);
    expect(result.financialSummary.driverTransferredEarnings90Percent).toBe(1800);
    expect(result.financialSummary.destinationBankAccount.iban).toBe('SA0380000000608010167519');
    expect(result.financialSummary.destinationBankAccount.transferStatus).toBe('TRANSFERRED_TO_BANK');
  });
});
