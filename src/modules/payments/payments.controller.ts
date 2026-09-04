import { Controller, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { ProcessEscrowPaymentDto } from './dto/process-payment.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('المدفوعات والضمان المالي (Payments & Escrow)')
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('process-escrow')
  @ApiBearerAuth()
  @Roles(Role.CLIENT)
  @ApiOperation({
    summary: 'سداد قيمة العرض المختار وحجز المبلغ في ضمان ترحيل مع إظهار التحذير الصارم من الدفع النقدي',
  })
  @ApiResponse({ status: 200, description: 'تم الدفع بنجاح وتفعيل العقد في الضمان المالي' })
  processEscrowPayment(@CurrentUser('id') clientId: string, @Body() dto: ProcessEscrowPaymentDto) {
    return this.paymentsService.processEscrowPayment(clientId, dto);
  }

  @Post('complete-contract/:contractId')
  @ApiBearerAuth()
  @Roles(Role.CLIENT, Role.ADMIN)
  @ApiOperation({
    summary: 'تأكيد انتهاء مدة التوصيل، خصم عمولة ترحيل 10%، تحويل 90% للسائق، وطلب التقييم من العميل',
  })
  @ApiResponse({ status: 200, description: 'تم تحرير مستحقات السائق وطلب التقييم من العميل' })
  completeContractAndReleaseFunds(
    @CurrentUser('id') userId: string,
    @Param('contractId') contractId: string,
  ) {
    return this.paymentsService.completeContractAndReleaseFunds(contractId, userId);
  }
}
