import { Controller, Post, Get, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { ContractsService } from './contracts.service';
import { AcceptOfferDto } from './dto/accept-offer.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('عقود المشاوير والتعاقدات (Trip Contracts)')
@Controller('contracts')
export class ContractsController {
  constructor(private readonly contractsService: ContractsService) {}

  @Post('accept-offer')
  @ApiBearerAuth()
  @Roles(Role.CLIENT)
  @ApiOperation({
    summary: 'قبول عرض سعر من سائق وإنشاء عقد الرحلة وإشعار السائق بالموعد والتنبيه بعدم الدفع النقدي',
  })
  @ApiResponse({ status: 201, description: 'تم قبول العرض بنجاح وإنشاء العقد' })
  acceptOffer(@CurrentUser('id') clientId: string, @Body() dto: AcceptOfferDto) {
    return this.contractsService.acceptOffer(clientId, dto);
  }

  @Get('my-contracts')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'استعراض جميع عقود المستخدم (عميل أو سائق)' })
  getMyContracts(@CurrentUser('id') userId: string) {
    return this.contractsService.getMyContracts(userId);
  }

  @Get(':id')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'استرجاع تفاصيل عقد التوصيل بالكامل مع حالة الضمان المالي' })
  getContractById(@CurrentUser('id') userId: string, @Param('id') contractId: string) {
    return this.contractsService.getContractById(contractId, userId);
  }
}
