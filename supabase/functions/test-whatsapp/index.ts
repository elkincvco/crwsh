import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

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
    const { phoneNumber, message } = await req.json()

    console.log('📱 Testing WhatsApp message to:', phoneNumber)
    console.log('📝 Message:', message)

    // WhatsApp credentials from Meta
    const whatsappToken = 'EAATo85JRkBMBPFgLOCXw1eYMbw2HZA3eaAXTXGSYJbSZCNjxwVQRZCzweXmZC6Cs0lQQUzmZBE8RYIZA5xuGi35ZB3SJhuLk3VKUiZAuzxNTLZC8V5mMNPikv8IpWNDVfBGJkt304xXkwoUJppGPDdC4CVMZA52H8XZBbnnlFGZBH324ZCCPbUNC4T4eRGnll0DwYdKrfdDdfMolOXWJHcdrzpjo3k8ZBR8ddzZBDJSHFCXKRiuFzgOowZDZD'
    const whatsappPhoneNumberId = '762748226913193'
    
    // Format phone number (remove + and ensure it starts with country code)
    const formattedPhone = formatPhoneNumber(phoneNumber)
    
    console.log('📤 Sending to formatted number:', formattedPhone)

    // Additional debugging
    console.log('🔧 API Configuration:', {
      whatsappToken: whatsappToken ? `${whatsappToken.substring(0, 20)}...` : 'NOT SET',
      whatsappPhoneNumberId,
      apiUrl: `https://graph.facebook.com/v18.0/${whatsappPhoneNumberId}/messages`
    })

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
          to: formattedPhone,
          type: 'text',
          text: {
            body: message
          }
        })
      }
    )

    const result = await response.json()
    
    console.log('📊 WhatsApp API Response Status:', response.status)
    console.log('📊 WhatsApp API Response:', result)
    
    if (!response.ok) {
      console.error('❌ WhatsApp API Error:', result)
      throw new Error(`WhatsApp API Error: ${result.error?.message || 'Unknown error'}`)
    }

    console.log('✅ WhatsApp message sent successfully!')
    
    return new Response(
      JSON.stringify({ 
        success: true, 
        result,
        formattedPhone,
        status: response.status
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )

  } catch (error) {
    console.error('❌ WhatsApp test error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message,
        details: error.toString()
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})

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
  
  // For testing, if it's a US number format, keep as is
  if (cleaned.startsWith('1') && cleaned.length === 11) {
    return cleaned
  }
  
  return cleaned
}
