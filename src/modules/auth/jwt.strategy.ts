import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private prisma: PrismaService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET || 'tarheel_super_secure_jwt_secret_key_2026_production_grade',
    });
  }

  async validate(payload: { sub: string; role: string; phoneNumber: string }) {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: { driverProfile: { include: { vehicle: true } } },
    });

    if (!user) {
      throw new UnauthorizedException('المستخدم غير موجود أو تم إلغاء حسابه');
    }

    if (user.isBlocked) {
      throw new UnauthorizedException('تم حظر هذا الحساب لمخالفة سياسات ترحيل');
    }

    return user;
  }
}
