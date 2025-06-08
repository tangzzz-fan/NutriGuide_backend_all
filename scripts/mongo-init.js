// MongoDB 初始化脚本
// 为 NutriGuide 项目创建数据库、集合和索引

print('🚀 开始初始化 NutriGuide 数据库...');

// 获取环境变量或使用默认值
const dbName = process.env.MONGO_INITDB_DATABASE || 'nutriguide_dev';
const environment = process.env.NODE_ENV || 'development';

print(`📊 当前环境: ${environment}`);
print(`🗄️  目标数据库: ${dbName}`);

// 切换到目标数据库
db = db.getSiblingDB(dbName);

// 创建集合和索引
print('📝 创建用户相关集合...');

// 用户集合
db.createCollection('users');
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ username: 1 }, { unique: true });
db.users.createIndex({ phone: 1 }, { sparse: true });
db.users.createIndex({ createdAt: 1 });
db.users.createIndex({ 'profile.preferences': 1 });

// 认证令牌集合
db.createCollection('authtokens');
db.authtokens.createIndex({ token: 1 }, { unique: true });
db.authtokens.createIndex({ userId: 1 });
db.authtokens.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// 短信验证集合
db.createCollection('smsverifications');
db.smsverifications.createIndex({ phone: 1, type: 1 });
db.smsverifications.createIndex({ code: 1 });
db.smsverifications.createIndex({ expiresAt: 1 }, { expireAfterSeconds: 0 });

print('🍎 创建食品相关集合...');

// 食品数据集合
db.createCollection('foods');
db.foods.createIndex({ name: 1 });
db.foods.createIndex({ barcode: 1 }, { sparse: true });
db.foods.createIndex({ category: 1 });
db.foods.createIndex({ brand: 1 });
db.foods.createIndex({ 'nutrition.calories': 1 });
db.foods.createIndex({ tags: 1 });
db.foods.createIndex({ isVerified: 1 });

// 膳食记录集合
db.createCollection('mealrecords');
db.mealrecords.createIndex({ userId: 1 });
db.mealrecords.createIndex({ date: 1 });
db.mealrecords.createIndex({ mealType: 1 });
db.mealrecords.createIndex({ userId: 1, date: 1 });


// 仅在开发环境插入示例数据
if (environment === 'development') {
    print('🌱 插入开发环境示例数据...');

    // 示例食品
    db.foods.insertMany([
        {
            name: '苹果',
            brand: '新鲜水果',
            category: '水果',
            nutrition: {
                calories: 52,
                protein: 0.3,
                fat: 0.2,
                carbohydrates: 14,
                fiber: 2.4
            },
            servingSize: '100g',
            tags: ['健康', '天然', '低卡路里'],
            isVerified: true,
            createdAt: new Date()
        }
    ]);

    print('✅ 开发环境示例数据插入完成');
}

print('🎉 NutriGuide 数据库初始化完成！'); 