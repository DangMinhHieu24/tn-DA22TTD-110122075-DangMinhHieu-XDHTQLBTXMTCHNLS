import { Request, Response } from 'express';
import { prisma } from '../prisma';
import * as ExcelJS from 'exceljs';

/**
 * Get warranties for a specific vehicle
 * GET /api/vehicles/:vehicleId/warranties
 * Access: All roles (with permission check)
 */
export const getVehicleWarranties = async (req: Request, res: Response) => {
  try {
    const { vehicleId } = req.params;
    const authUser = (req as any).user;

    // Check if vehicle exists
    const vehicle = await prisma.vehicle.findUnique({
      where: { id: vehicleId },
      select: {
        id: true,
        licensePlate: true,
        brand: true,
        model: true,
        color: true,
        imageUrl: true,
        manufactureYear: true,
        currentKm: true,
        ownerId: true,
      },
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found',
      });
    }

    // Permission check: CUSTOMER can only view their own vehicles
    if (authUser?.role === 'CUSTOMER' && vehicle.ownerId !== authUser.userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You can only view warranties of your own vehicles',
      });
    }

    // Fetch warranties
    const warranties = await prisma.warranty.findMany({
      where: { vehicleId },
      orderBy: {
        expiryDate: 'asc',
      },
    });

    // Fetch part warranties
    const partWarranties = await prisma.partWarranty.findMany({
      where: { vehicleId },
      include: {
        part: {
          select: { partName: true },
        },
      },
      orderBy: {
        expiryDate: 'asc',
      },
    });

    // Calculate status and days remaining for each warranty
    const now = new Date();
    const warrantiesWithStatus = warranties.map((warranty) => {
      const expiryDate = new Date(warranty.expiryDate);
      const daysRemaining = Math.ceil((expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
      
      let status: 'ACTIVE' | 'EXPIRING_SOON' | 'EXPIRED';
      if (daysRemaining < 0) {
        status = 'EXPIRED';
      } else if (daysRemaining <= 30) {
        status = 'EXPIRING_SOON';
      } else {
        status = 'ACTIVE';
      }

      return {
        ...warranty,
        daysRemaining,
        status,
      };
    });

    // Calculate status and days remaining for each part warranty
    const partWarrantiesWithStatus = partWarranties.map((pw) => {
      const expiryDate = new Date(pw.expiryDate);
      const daysRemaining = Math.ceil((expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));

      let status: 'ACTIVE' | 'EXPIRING_SOON' | 'EXPIRED';
      if (daysRemaining < 0) {
        status = 'EXPIRED';
      } else if (daysRemaining <= 30) {
        status = 'EXPIRING_SOON';
      } else {
        status = 'ACTIVE';
      }

      return {
        id: pw.id,
        partId: pw.partId,
        partName: pw.part.partName,
        workOrderId: pw.workOrderId,
        warrantyDays: pw.warrantyDays,
        startDate: pw.startDate,
        expiryDate: pw.expiryDate,
        daysRemaining,
        status,
      };
    });

    res.json({
      success: true,
      data: {
        vehicle,
        warranties: warrantiesWithStatus,
        partWarranties: partWarrantiesWithStatus,
      },
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch warranties',
      error: error.message,
    });
  }
};

/**
 * Get all warranties (Admin only)
 * GET /api/warranties
 * Access: ADMIN only
 */
export const getAllWarranties = async (req: Request, res: Response) => {
  try {
    const { status, expiringSoon } = req.query;

    const now = new Date();
    const whereWarranty: any = {};
    const whereVehicle: any = {
      warrantyExpiry: {
        not: null,
      },
    };

    if (expiringSoon === 'true') {
      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(now.getDate() + 30);
      
      whereWarranty.expiryDate = {
        gte: now,
        lte: thirtyDaysFromNow,
      };
      whereVehicle.warrantyExpiry = {
        gte: now,
        lte: thirtyDaysFromNow,
      };
    } else if (status === 'EXPIRED') {
      whereWarranty.expiryDate = {
        lt: now,
      };
      whereVehicle.warrantyExpiry = {
        lt: now,
      };
    } else if (status === 'ACTIVE') {
      whereWarranty.expiryDate = {
        gte: now,
      };
      whereVehicle.warrantyExpiry = {
        gte: now,
      };
    }

    // 1. Fetch manual warranties
    const warranties = await prisma.warranty.findMany({
      where: whereWarranty,
      include: {
        vehicle: {
          select: {
            id: true,
            licensePlate: true,
            brand: true,
            model: true,
            owner: {
              select: {
                id: true,
                name: true,
                email: true,
                phoneNumber: true,
              },
            },
          },
        },
      },
    });

    // 2. Fetch vehicles with warrantyExpiry
    const vehiclesWithWarranty = await prisma.vehicle.findMany({
      where: whereVehicle,
      include: {
        owner: {
          select: {
            id: true,
            name: true,
            email: true,
            phoneNumber: true,
          },
        },
      },
    });

    // Map manual warranties with calculated status
    const manualWarrantiesWithStatus = warranties.map((warranty) => {
      const expiryDate = new Date(warranty.expiryDate);
      const daysRemaining = Math.ceil((expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
      
      let calculatedStatus: 'ACTIVE' | 'EXPIRING_SOON' | 'EXPIRED';
      if (daysRemaining < 0) {
        calculatedStatus = 'EXPIRED';
      } else if (daysRemaining <= 30) {
        calculatedStatus = 'EXPIRING_SOON';
      } else {
        calculatedStatus = 'ACTIVE';
      }

      return {
        ...warranty,
        daysRemaining,
        status: calculatedStatus,
      };
    });

    // Map vehicle general warranties into unified Warranty format
    const vehicleWarrantiesMapped = vehiclesWithWarranty.map((vehicle) => {
      const expiryDate = new Date(vehicle.warrantyExpiry!);
      const daysRemaining = Math.ceil((expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
      
      let calculatedStatus: 'ACTIVE' | 'EXPIRING_SOON' | 'EXPIRED';
      if (daysRemaining < 0) {
        calculatedStatus = 'EXPIRED';
      } else if (daysRemaining <= 30) {
        calculatedStatus = 'EXPIRING_SOON';
      } else {
        calculatedStatus = 'ACTIVE';
      }

      return {
        id: `veh-gen-${vehicle.id}`,
        vehicleId: vehicle.id,
        warrantyType: 'Bảo hành chung của xe',
        startDate: vehicle.createdAt,
        expiryDate: vehicle.warrantyExpiry!,
        terms: 'Điều khoản bảo hành tổng thể xe điện theo tiêu chuẩn.',
        issuedBy: vehicle.brand || 'Hãng sản xuất',
        daysRemaining,
        status: calculatedStatus,
        vehicle: {
          id: vehicle.id,
          licensePlate: vehicle.licensePlate,
          brand: vehicle.brand,
          model: vehicle.model,
          owner: vehicle.owner,
        },
      };
    });

    // Combine both lists and sort by expiry date ascending
    const combinedWarranties = [...manualWarrantiesWithStatus, ...vehicleWarrantiesMapped];
    combinedWarranties.sort((a, b) => new Date(a.expiryDate).getTime() - new Date(b.expiryDate).getTime());

    res.json({
      success: true,
      data: combinedWarranties,
      count: combinedWarranties.length,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch warranties',
      error: error.message,
    });
  }
};

/**
 * Get warranty by ID
 * GET /api/warranties/:id
 * Access: All roles (with permission check)
 */
export const getWarrantyById = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const authUser = (req as any).user;

    const warranty = await prisma.warranty.findUnique({
      where: { id },
      include: {
        vehicle: {
          select: {
            id: true,
            licensePlate: true,
            brand: true,
            model: true,
            ownerId: true,
          },
        },
      },
    });

    if (!warranty) {
      return res.status(404).json({
        success: false,
        message: 'Warranty not found',
      });
    }

    // Permission check
    if (authUser?.role === 'CUSTOMER' && warranty.vehicle.ownerId !== authUser.userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied',
      });
    }

    res.json({
      success: true,
      data: warranty,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch warranty',
      error: error.message,
    });
  }
};

/**
 * Create new warranty
 * POST /api/warranties
 * Access: ADMIN only
 */
export const createWarranty = async (req: Request, res: Response) => {
  try {
    const {
      vehicleId,
      warrantyType,
      startDate,
      expiryDate,
      terms,
      issuedBy,
    } = req.body;

    // Validation
    if (!vehicleId || !warrantyType || !startDate || !expiryDate) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: vehicleId, warrantyType, startDate, expiryDate',
      });
    }

    // Check if vehicle exists
    const vehicle = await prisma.vehicle.findUnique({
      where: { id: vehicleId },
    });

    if (!vehicle) {
      return res.status(404).json({
        success: false,
        message: 'Vehicle not found',
      });
    }

    // Validate dates
    const start = new Date(startDate);
    const expiry = new Date(expiryDate);

    if (expiry <= start) {
      return res.status(400).json({
        success: false,
        message: 'Expiry date must be after start date',
      });
    }

    const warranty = await prisma.warranty.create({
      data: {
        vehicleId,
        warrantyType,
        startDate: start,
        expiryDate: expiry,
        terms,
        issuedBy,
      },
      include: {
        vehicle: {
          select: {
            id: true,
            licensePlate: true,
            brand: true,
            model: true,
          },
        },
      },
    });

    res.status(201).json({
      success: true,
      message: 'Warranty created successfully',
      data: warranty,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to create warranty',
      error: error.message,
    });
  }
};

/**
 * Update warranty
 * PUT /api/warranties/:id
 * Access: ADMIN only
 */
export const updateWarranty = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const {
      warrantyType,
      startDate,
      expiryDate,
      terms,
      issuedBy,
    } = req.body;

    // Check if warranty exists
    const existingWarranty = await prisma.warranty.findUnique({
      where: { id },
    });

    if (!existingWarranty) {
      return res.status(404).json({
        success: false,
        message: 'Warranty not found',
      });
    }

    // Validate dates if provided
    if (startDate && expiryDate) {
      const start = new Date(startDate);
      const expiry = new Date(expiryDate);

      if (expiry <= start) {
        return res.status(400).json({
          success: false,
          message: 'Expiry date must be after start date',
        });
      }
    }

    const updateData: any = {};
    if (warrantyType !== undefined) updateData.warrantyType = warrantyType;
    if (startDate !== undefined) updateData.startDate = new Date(startDate);
    if (expiryDate !== undefined) updateData.expiryDate = new Date(expiryDate);
    if (terms !== undefined) updateData.terms = terms;
    if (issuedBy !== undefined) updateData.issuedBy = issuedBy;

    const warranty = await prisma.warranty.update({
      where: { id },
      data: updateData,
      include: {
        vehicle: {
          select: {
            id: true,
            licensePlate: true,
            brand: true,
            model: true,
          },
        },
      },
    });

    res.json({
      success: true,
      message: 'Warranty updated successfully',
      data: warranty,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to update warranty',
      error: error.message,
    });
  }
};

/**
 * Delete warranty
 * DELETE /api/warranties/:id
 * Access: ADMIN only
 */
export const deleteWarranty = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    // Check if warranty exists
    const warranty = await prisma.warranty.findUnique({
      where: { id },
    });

    if (!warranty) {
      return res.status(404).json({
        success: false,
        message: 'Warranty not found',
      });
    }

    await prisma.warranty.delete({
      where: { id },
    });

    res.json({
      success: true,
      message: 'Warranty deleted successfully',
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete warranty',
      error: error.message,
    });
  }
};

/**
 * Export warranty data by year (For authorities)
 * GET /api/warranties/export/:year
 * Access: ADMIN and STAFF only
 */
export const exportWarrantyDataByYear = async (req: Request, res: Response) => {
  try {
    const { year } = req.params;
    const authUser = (req as any).user;

    // Permission check
    if (authUser?.role !== 'ADMIN' && authUser?.role !== 'STAFF') {
      return res.status(403).json({
        success: false,
        message: 'Access denied: Only administrators and staff can export data',
      });
    }

    const targetYear = parseInt(year);
    if (isNaN(targetYear) || targetYear < 2000 || targetYear > 2100) {
      return res.status(400).json({
        success: false,
        message: 'Invalid year format',
      });
    }

    // Date range for the year
    const startDate = new Date(`${targetYear}-01-01T00:00:00.000Z`);
    const endDate = new Date(`${targetYear}-12-31T23:59:59.999Z`);

    // 1. Get all warranties activated in this year
    const warranties = await prisma.warranty.findMany({
      where: {
        startDate: {
          gte: startDate,
          lte: endDate,
        },
      },
      include: {
        vehicle: {
          include: {
            owner: {
              select: {
                id: true,
                name: true,
                email: true,
                phoneNumber: true,
                address: true,
              },
            },
          },
        },
      },
      orderBy: {
        startDate: 'asc',
      },
    });

    // 2. Get all part warranties from work orders in this year
    const workOrders = await prisma.workOrder.findMany({
      where: {
        createdAt: {
          gte: startDate,
          lte: endDate,
        },
      },
      include: {
        vehicle: {
          include: {
            owner: {
              select: {
                id: true,
                name: true,
                email: true,
                phoneNumber: true,
                address: true,
              },
            },
          },
        },
        partWarranties: {
          include: {
            part: {
              select: {
                partName: true,
                price: true,
              },
            },
          },
        },
        parts: {
          include: {
            part: {
              select: {
                partName: true,
                price: true,
              },
            },
          },
        },
      },
      orderBy: {
        createdAt: 'asc',
      },
    });

    // 3. Create Excel workbook
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'Xanh EV System';
    workbook.created = new Date();

    // Sheet 1: Warranty Summary
    const summarySheet = workbook.addWorksheet('Tổng quan');
    summarySheet.columns = [
      { header: 'Mã bảo hành', key: 'warrantyId', width: 20 },
      { header: 'Loại bảo hành', key: 'warrantyType', width: 25 },
      { header: 'Biển số xe', key: 'licensePlate', width: 15 },
      { header: 'Mã VIN', key: 'vin', width: 20 },
      { header: 'Hãng xe', key: 'brand', width: 15 },
      { header: 'Model', key: 'model', width: 15 },
      { header: 'Tên khách hàng', key: 'customerName', width: 25 },
      { header: 'Số điện thoại', key: 'phoneNumber', width: 15 },
      { header: 'Email', key: 'email', width: 25 },
      { header: 'Địa chỉ', key: 'address', width: 35 },
      { header: 'Ngày bắt đầu', key: 'startDate', width: 15 },
      { header: 'Ngày hết hạn', key: 'expiryDate', width: 15 },
      { header: 'Đơn vị cấp', key: 'issuedBy', width: 20 },
      { header: 'Điều khoản', key: 'terms', width: 40 },
    ];

    // Style header
    summarySheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    summarySheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF006E2F' },
    };
    summarySheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };

    // Add data
    warranties.forEach((warranty) => {
      summarySheet.addRow({
        warrantyId: warranty.id,
        warrantyType: warranty.warrantyType,
        licensePlate: warranty.vehicle.licensePlate,
        vin: warranty.vehicle.vin || 'N/A',
        brand: warranty.vehicle.brand || 'N/A',
        model: warranty.vehicle.model || 'N/A',
        customerName: warranty.vehicle.owner?.name || 'N/A',
        phoneNumber: warranty.vehicle.owner?.phoneNumber || 'N/A',
        email: warranty.vehicle.owner?.email || 'N/A',
        address: warranty.vehicle.owner?.address || 'N/A',
        startDate: warranty.startDate.toISOString().split('T')[0],
        expiryDate: warranty.expiryDate.toISOString().split('T')[0],
        issuedBy: warranty.issuedBy || 'Xanh EV',
        terms: warranty.terms || '',
      });
    });

    // Sheet 2: Work Orders & Maintenance History
    const workOrderSheet = workbook.addWorksheet('Lịch sử bảo dưỡng');
    workOrderSheet.columns = [
      { header: 'Mã đơn hàng', key: 'workOrderId', width: 20 },
      { header: 'Biển số xe', key: 'licensePlate', width: 15 },
      { header: 'Tên khách hàng', key: 'customerName', width: 25 },
      { header: 'Số điện thoại', key: 'phoneNumber', width: 15 },
      { header: 'Ngày tiếp nhận', key: 'createdAt', width: 15 },
      { header: 'Ngày hoàn thành', key: 'completedAt', width: 15 },
      { header: 'Trạng thái', key: 'status', width: 15 },
      { header: 'Tổng chi phí', key: 'totalCost', width: 15 },
      { header: 'Mô tả công việc', key: 'description', width: 40 },
    ];

    // Style header
    workOrderSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    workOrderSheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF3B82F6' },
    };
    workOrderSheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };

    // Add data
    workOrders.forEach((wo) => {
      const statusMap: Record<string, string> = {
        PENDING: 'Chờ xử lý',
        IN_PROGRESS: 'Đang xử lý',
        COMPLETED: 'Hoàn thành',
        CANCELLED: 'Đã hủy',
      };

      workOrderSheet.addRow({
        workOrderId: wo.id,
        licensePlate: wo.vehicle.licensePlate,
        customerName: wo.vehicle.owner?.name || 'N/A',
        phoneNumber: wo.vehicle.owner?.phoneNumber || 'N/A',
        createdAt: wo.createdAt.toISOString().split('T')[0],
        completedAt: wo.completedAt ? wo.completedAt.toISOString().split('T')[0] : 'N/A',
        status: statusMap[wo.status] || wo.status,
        totalCost: wo.totalCost || 0,
        description: wo.description || '',
      });
    });

    // Sheet 3: Part Warranties
    const partWarrantySheet = workbook.addWorksheet('Bảo hành phụ tùng');
    partWarrantySheet.columns = [
      { header: 'Mã bảo hành', key: 'warrantyId', width: 20 },
      { header: 'Mã đơn hàng', key: 'workOrderId', width: 20 },
      { header: 'Tên phụ tùng', key: 'partName', width: 30 },
      { header: 'Giá', key: 'price', width: 15 },
      { header: 'Biển số xe', key: 'licensePlate', width: 15 },
      { header: 'Tên khách hàng', key: 'customerName', width: 25 },
      { header: 'Số điện thoại', key: 'phoneNumber', width: 15 },
      { header: 'Thời hạn BH (ngày)', key: 'warrantyDays', width: 15 },
      { header: 'Ngày bắt đầu', key: 'startDate', width: 15 },
      { header: 'Ngày hết hạn', key: 'expiryDate', width: 15 },
    ];

    // Style header
    partWarrantySheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    partWarrantySheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFD97706' },
    };
    partWarrantySheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };

    // Add data
    workOrders.forEach((wo) => {
      wo.partWarranties.forEach((pw) => {
        partWarrantySheet.addRow({
          warrantyId: pw.id,
          workOrderId: wo.id,
          partName: pw.part.partName,
          price: pw.part.price,
          licensePlate: wo.vehicle.licensePlate,
          customerName: wo.vehicle.owner?.name || 'N/A',
          phoneNumber: wo.vehicle.owner?.phoneNumber || 'N/A',
          warrantyDays: pw.warrantyDays,
          startDate: pw.startDate.toISOString().split('T')[0],
          expiryDate: pw.expiryDate.toISOString().split('T')[0],
        });
      });
    });

    // Sheet 4: Statistics
    const statsSheet = workbook.addWorksheet('Thống kê');
    statsSheet.mergeCells('A1:B1');
    statsSheet.getCell('A1').value = `BÁO CÁO THỐNG KÊ NĂM ${targetYear}`;
    statsSheet.getCell('A1').font = { bold: true, size: 16, color: { argb: 'FF006E2F' } };
    statsSheet.getCell('A1').alignment = { horizontal: 'center', vertical: 'middle' };

    statsSheet.addRow([]);
    statsSheet.addRow(['Chỉ số', 'Giá trị']);
    statsSheet.getRow(3).font = { bold: true };

    const totalPartWarranties = workOrders.reduce((sum, wo) => sum + wo.partWarranties.length, 0);
    const totalRevenue = workOrders.reduce((sum, wo) => sum + (wo.totalCost || 0), 0);
    const completedWorkOrders = workOrders.filter(wo => wo.status === 'COMPLETED').length;

    statsSheet.addRow(['Tổng số bảo hành tổng thể', warranties.length]);
    statsSheet.addRow(['Tổng số đơn hàng', workOrders.length]);
    statsSheet.addRow(['Đơn hàng hoàn thành', completedWorkOrders]);
    statsSheet.addRow(['Tổng số bảo hành phụ tùng', totalPartWarranties]);
    statsSheet.addRow(['Tổng doanh thu (VNĐ)', totalRevenue]);

    statsSheet.getColumn(1).width = 30;
    statsSheet.getColumn(2).width = 20;

    // Generate buffer
    const buffer = await workbook.xlsx.writeBuffer();

    // Set response headers
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    res.setHeader(
      'Content-Disposition',
      `attachment; filename=warranty-data-${targetYear}.xlsx`
    );

    res.send(buffer);
  } catch (error: any) {
    console.error('Export error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to export warranty data',
      error: error.message,
    });
  }
};

/**
 * Export all warranty data (All years)
 * GET /api/warranties/export/all
 * Access: ADMIN and STAFF only
 */
export const exportAllWarrantyData = async (req: Request, res: Response) => {
  try {
    const authUser = (req as any).user;

    // Permission check
    if (authUser?.role !== 'ADMIN' && authUser?.role !== 'STAFF') {
      return res.status(403).json({
        success: false,
        message: 'Access denied: Only administrators and staff can export data',
      });
    }

    // 1. Get all warranties
    const warranties = await prisma.warranty.findMany({
      include: {
        vehicle: {
          include: {
            owner: {
              select: {
                id: true,
                name: true,
                email: true,
                phoneNumber: true,
                address: true,
              },
            },
          },
        },
      },
      orderBy: {
        startDate: 'desc',
      },
    });

    // 2. Get all work orders
    const workOrders = await prisma.workOrder.findMany({
      include: {
        vehicle: {
          include: {
            owner: {
              select: {
                id: true,
                name: true,
                email: true,
                phoneNumber: true,
                address: true,
              },
            },
          },
        },
        partWarranties: {
          include: {
            part: {
              select: {
                partName: true,
                price: true,
              },
            },
          },
        },
        parts: {
          include: {
            part: {
              select: {
                partName: true,
                price: true,
              },
            },
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    // 3. Create Excel workbook
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'Xanh EV System';
    workbook.created = new Date();

    // Sheet 1: Warranty Summary
    const summarySheet = workbook.addWorksheet('Tổng quan');
    summarySheet.columns = [
      { header: 'Mã bảo hành', key: 'warrantyId', width: 20 },
      { header: 'Loại bảo hành', key: 'warrantyType', width: 25 },
      { header: 'Biển số xe', key: 'licensePlate', width: 15 },
      { header: 'Mã VIN', key: 'vin', width: 20 },
      { header: 'Hãng xe', key: 'brand', width: 15 },
      { header: 'Model', key: 'model', width: 15 },
      { header: 'Tên khách hàng', key: 'customerName', width: 25 },
      { header: 'Số điện thoại', key: 'phoneNumber', width: 15 },
      { header: 'Email', key: 'email', width: 25 },
      { header: 'Địa chỉ', key: 'address', width: 35 },
      { header: 'Ngày bắt đầu', key: 'startDate', width: 15 },
      { header: 'Ngày hết hạn', key: 'expiryDate', width: 15 },
      { header: 'Đơn vị cấp', key: 'issuedBy', width: 20 },
      { header: 'Điều khoản', key: 'terms', width: 40 },
    ];

    // Style header
    summarySheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    summarySheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF006E2F' },
    };
    summarySheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };

    // Add data
    warranties.forEach((warranty) => {
      summarySheet.addRow({
        warrantyId: warranty.id,
        warrantyType: warranty.warrantyType,
        licensePlate: warranty.vehicle.licensePlate,
        vin: warranty.vehicle.vin || 'N/A',
        brand: warranty.vehicle.brand || 'N/A',
        model: warranty.vehicle.model || 'N/A',
        customerName: warranty.vehicle.owner?.name || 'N/A',
        phoneNumber: warranty.vehicle.owner?.phoneNumber || 'N/A',
        email: warranty.vehicle.owner?.email || 'N/A',
        address: warranty.vehicle.owner?.address || 'N/A',
        startDate: warranty.startDate.toISOString().split('T')[0],
        expiryDate: warranty.expiryDate.toISOString().split('T')[0],
        issuedBy: warranty.issuedBy || 'Xanh EV',
        terms: warranty.terms || '',
      });
    });

    // Sheet 2: Work Orders & Maintenance History
    const workOrderSheet = workbook.addWorksheet('Lịch sử bảo dưỡng');
    workOrderSheet.columns = [
      { header: 'Mã đơn hàng', key: 'workOrderId', width: 20 },
      { header: 'Biển số xe', key: 'licensePlate', width: 15 },
      { header: 'Tên khách hàng', key: 'customerName', width: 25 },
      { header: 'Số điện thoại', key: 'phoneNumber', width: 15 },
      { header: 'Ngày tiếp nhận', key: 'createdAt', width: 15 },
      { header: 'Ngày hoàn thành', key: 'completedAt', width: 15 },
      { header: 'Trạng thái', key: 'status', width: 15 },
      { header: 'Tổng chi phí', key: 'totalCost', width: 15 },
      { header: 'Mô tả công việc', key: 'description', width: 40 },
    ];

    // Style header
    workOrderSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    workOrderSheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF3B82F6' },
    };
    workOrderSheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };

    // Add data
    workOrders.forEach((wo) => {
      const statusMap: Record<string, string> = {
        PENDING: 'Chờ xử lý',
        IN_PROGRESS: 'Đang xử lý',
        COMPLETED: 'Hoàn thành',
        CANCELLED: 'Đã hủy',
      };

      workOrderSheet.addRow({
        workOrderId: wo.id,
        licensePlate: wo.vehicle.licensePlate,
        customerName: wo.vehicle.owner?.name || 'N/A',
        phoneNumber: wo.vehicle.owner?.phoneNumber || 'N/A',
        createdAt: wo.createdAt.toISOString().split('T')[0],
        completedAt: wo.completedAt ? wo.completedAt.toISOString().split('T')[0] : 'N/A',
        status: statusMap[wo.status] || wo.status,
        totalCost: wo.totalCost || 0,
        description: wo.description || '',
      });
    });

    // Sheet 3: Part Warranties
    const partWarrantySheet = workbook.addWorksheet('Bảo hành phụ tùng');
    partWarrantySheet.columns = [
      { header: 'Mã bảo hành', key: 'warrantyId', width: 20 },
      { header: 'Mã đơn hàng', key: 'workOrderId', width: 20 },
      { header: 'Tên phụ tùng', key: 'partName', width: 30 },
      { header: 'Giá', key: 'price', width: 15 },
      { header: 'Biển số xe', key: 'licensePlate', width: 15 },
      { header: 'Tên khách hàng', key: 'customerName', width: 25 },
      { header: 'Số điện thoại', key: 'phoneNumber', width: 15 },
      { header: 'Thời hạn BH (ngày)', key: 'warrantyDays', width: 15 },
      { header: 'Ngày bắt đầu', key: 'startDate', width: 15 },
      { header: 'Ngày hết hạn', key: 'expiryDate', width: 15 },
    ];

    // Style header
    partWarrantySheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    partWarrantySheet.getRow(1).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFD97706' },
    };
    partWarrantySheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };

    // Add data
    workOrders.forEach((wo) => {
      wo.partWarranties.forEach((pw) => {
        partWarrantySheet.addRow({
          warrantyId: pw.id,
          workOrderId: wo.id,
          partName: pw.part.partName,
          price: pw.part.price,
          licensePlate: wo.vehicle.licensePlate,
          customerName: wo.vehicle.owner?.name || 'N/A',
          phoneNumber: wo.vehicle.owner?.phoneNumber || 'N/A',
          warrantyDays: pw.warrantyDays,
          startDate: pw.startDate.toISOString().split('T')[0],
          expiryDate: pw.expiryDate.toISOString().split('T')[0],
        });
      });
    });

    // Sheet 4: Statistics
    const statsSheet = workbook.addWorksheet('Thống kê');
    statsSheet.mergeCells('A1:B1');
    statsSheet.getCell('A1').value = 'BÁO CÁO THỐNG KÊ TỔNG HỢP';
    statsSheet.getCell('A1').font = { bold: true, size: 16, color: { argb: 'FF006E2F' } };
    statsSheet.getCell('A1').alignment = { horizontal: 'center', vertical: 'middle' };

    statsSheet.addRow([]);
    statsSheet.addRow(['Chỉ số', 'Giá trị']);
    statsSheet.getRow(3).font = { bold: true };

    const totalPartWarranties = workOrders.reduce((sum, wo) => sum + wo.partWarranties.length, 0);
    const totalRevenue = workOrders.reduce((sum, wo) => sum + (wo.totalCost || 0), 0);
    const completedWorkOrders = workOrders.filter(wo => wo.status === 'COMPLETED').length;

    statsSheet.addRow(['Tổng số bảo hành tổng thể', warranties.length]);
    statsSheet.addRow(['Tổng số đơn hàng', workOrders.length]);
    statsSheet.addRow(['Đơn hàng hoàn thành', completedWorkOrders]);
    statsSheet.addRow(['Tổng số bảo hành phụ tùng', totalPartWarranties]);
    statsSheet.addRow(['Tổng doanh thu (VNĐ)', totalRevenue]);

    // Get year range
    const years = new Set<number>();
    warranties.forEach(w => years.add(new Date(w.startDate).getFullYear()));
    workOrders.forEach(wo => years.add(new Date(wo.createdAt).getFullYear()));
    const yearRange = years.size > 0 
      ? `${Math.min(...years)} - ${Math.max(...years)}`
      : 'N/A';
    
    statsSheet.addRow(['Khoảng thời gian', yearRange]);

    statsSheet.getColumn(1).width = 30;
    statsSheet.getColumn(2).width = 20;

    // Generate buffer
    const buffer = await workbook.xlsx.writeBuffer();

    // Set response headers
    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    );
    res.setHeader(
      'Content-Disposition',
      'attachment; filename=warranty-data-all-years.xlsx'
    );

    res.send(buffer);
  } catch (error: any) {
    console.error('Export error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to export warranty data',
      error: error.message,
    });
  }
};
