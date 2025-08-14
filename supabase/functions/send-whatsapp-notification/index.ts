import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

interface WhatsAppNotificationRequest {
  appointmentId: string
  status: 'confirmed' | 'in_progress' | 'completed'
}

interface AppointmentData {
  customer_phone: string
  customer_name: string
  workspace_name: string
  workspace_address?: string
  service_name: string
  vehicle_plate: string
  appointment_date: string
  appointment_time: string
  status: string
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    const { appointmentId, status }: WhatsAppNotificationRequest = await req.json()

    console.log('📱 WhatsApp Notification Request:', { appointmentId, status })

    // Get appointment data with all necessary joins
    const appointmentData = await getAppointmentData(appointmentId)
    
    if (!appointmentData) {
      throw new Error('Appointment not found')
    }

    // Send WhatsApp message
    const result = await sendWhatsAppMessage(appointmentData, status)

    return new Response(
      JSON.stringify({ success: true, result }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('❌ WhatsApp notification error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})

async function getAppointmentData(appointmentId: string): Promise<AppointmentData | null> {
  try {
    // Create Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2')
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    const { data, error } = await supabase
      .from('appointments')
      .select(`
        customer_phone,
        customer_name,
        vehicle_plate,
        appointment_date,
        appointment_time,
        status,
        workspace:workspaces(name, address),
        service:workspace_services(name)
      `)
      .eq('id', appointmentId)
      .single()

    if (error) throw error

    return {
      customer_phone: data.customer_phone,
      customer_name: data.customer_name,
      workspace_name: data.workspace?.name || '',
      workspace_address: data.workspace?.address,
      service_name: data.service?.name || '',
      vehicle_plate: data.vehicle_plate,
      appointment_date: data.appointment_date,
      appointment_time: data.appointment_time,
      status: data.status
    }

  } catch (error) {
    console.error('❌ Error fetching appointment data:', error)
    return null
  }
}

async function sendWhatsAppMessage(data: AppointmentData, status: string): Promise<any> {
  const whatsappToken = Deno.env.get('WHATSAPP_ACCESS_TOKEN')
  const whatsappPhoneNumberId = Deno.env.get('WHATSAPP_PHONE_NUMBER_ID')
  
  if (!whatsappToken || !whatsappPhoneNumberId) {
    throw new Error('WhatsApp credentials not configured')
  }

  // Format phone number (remove + and ensure it starts with country code)
  const phoneNumber = formatPhoneNumber(data.customer_phone)
  
  // Generate message based on status
  const message = generateMessage(data, status)
  
  console.log('📤 Sending WhatsApp message to:', phoneNumber)
  console.log('📝 Message:', message)

  // Send message via Meta WhatsApp Business API
  const response = await fetch(
    `https://graph.facebook.com/v18.0/${whatsappPhoneNumberId}/messages`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${whatsappToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        messaging_product: 'whatsapp',
        to: phoneNumber,
        type: 'text',
        text: {
          body: message
        }
      })
    }
  )

  const result = await response.json()
  
  if (!response.ok) {
    console.error('❌ WhatsApp API Error:', result)
    throw new Error(`WhatsApp API Error: ${result.error?.message || 'Unknown error'}`)
  }

  console.log('✅ WhatsApp message sent successfully:', result)
  return result
}

function formatPhoneNumber(phone: string): string {
  // Remove all non-numeric characters
  let cleaned = phone.replace(/\D/g, '')
  
  // If it starts with +57 or 57, keep as is
  if (cleaned.startsWith('57') && cleaned.length === 12) {
    return cleaned
  }
  
  // If it's a Colombian number without country code, add 57
  if (cleaned.length === 10 && cleaned.startsWith('3')) {
    return '57' + cleaned
  }
  
  return cleaned
}

function generateMessage(data: AppointmentData, status: string): string {
  const formattedDate = formatDate(data.appointment_date)
  const formattedTime = formatTime(data.appointment_time)
  
  const baseInfo = `
🏢 *${data.workspace_name}*
👤 Cliente: ${data.customer_name}
🚗 Vehículo: ${data.vehicle_plate}
🛠️ Servicio: ${data.service_name}
📅 Fecha: ${formattedDate}
⏰ Hora: ${formattedTime}
${data.workspace_address ? `📍 Dirección: ${data.workspace_address}` : ''}
  `.trim()

  switch (status) {
    case 'confirmed':
      return `¡Hola ${data.customer_name}! 👋

✅ *Tu cita ha sido CONFIRMADA*

${baseInfo}

Nos vemos pronto para atender tu vehículo. ¡Gracias por confiar en nosotros! 🚗✨`

    case 'in_progress':
      return `¡Hola ${data.customer_name}! 👋

🔧 *Estamos comenzando el servicio de tu vehículo*

${baseInfo}

Nuestro equipo ya está trabajando en tu ${data.service_name}. Te notificaremos cuando esté listo. 🛠️`

    case 'completed':
      return `¡Hola ${data.customer_name}! 👋

🎉 *Tu servicio ha sido COMPLETADO*

${baseInfo}

Tu vehículo está listo para recoger. ¡Gracias por elegirnos! 

¿Cómo calificarías nuestro servicio? Tu opinión es muy importante para nosotros. ⭐`

    default:
      return `Hola ${data.customer_name}, hay una actualización en tu cita: ${status}`
  }
}

function formatDate(dateStr: string): string {
  const [year, month, day] = dateStr.split('-').map(Number)
  const date = new Date(year, month - 1, day)
  
  return date.toLocaleDateString('es-CO', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

function formatTime(timeStr: string): string {
  const [hours, minutes] = timeStr.split(':')
  const date = new Date()
  date.setHours(parseInt(hours), parseInt(minutes))
  
  return date.toLocaleTimeString('es-CO', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: true
  })
}
