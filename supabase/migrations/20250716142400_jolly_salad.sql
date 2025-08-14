/*
  # Insert Sample Workspaces

  1. Data Insertion
    - Insert two sample workspaces for testing
    - "AutoLavado Premium" - A premium car wash service
    - "Lavadero Express" - A quick service car wash
  
  2. Sample Data Features
    - Complete contact information
    - Realistic business descriptions
    - Different service approaches (premium vs express)
    - Both workspaces are active by default
*/

INSERT INTO workspaces (name, description, address, phone, email, logo_url, is_active) VALUES
(
  'AutoLavado Premium',
  'Servicio de lavado automotriz premium con atención personalizada y productos de alta calidad. Ofrecemos lavado completo, encerado, limpieza de interiores y servicios especializados.',
  'Av. Principal 123, Centro Comercial Plaza Norte, Local 45',
  '+57 300 123 4567',
  'info@autolavadopremium.com',
  'https://images.pexels.com/photos/3806288/pexels-photo-3806288.jpeg?auto=compress&cs=tinysrgb&w=200&h=200&fit=crop',
  true
),
(
  'Lavadero Express',
  'Lavado rápido y eficiente para conductores ocupados. Servicio express de alta calidad en menos de 30 minutos. Abierto 24/7 para tu comodidad.',
  'Calle 45 #67-89, Sector Industrial',
  '+57 301 987 6543',
  'contacto@lavaderoexpress.com',
  'https://images.pexels.com/photos/13065690/pexels-photo-13065690.jpeg?auto=compress&cs=tinysrgb&w=200&h=200&fit=crop',
  true
);