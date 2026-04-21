using System;

namespace CleanArchitecture.Core.DTOs.Ticket
{
    public class TicketDto
    {
        public Guid Id { get; set; }
        public string TicketNumber { get; set; }
        public string QrCode { get; set; }            // Mobil uygulama bu string'i QR koduna çevirir
        public DateTime PurchaseDate { get; set; }
        public bool IsUsed { get; set; }

        // Etkinlik bilgileri (bilet kartında gösterilir)
        public Guid EventId { get; set; }
        public string EventTitle { get; set; }
        public DateTime EventDate { get; set; }
        public string EventLocation { get; set; }
        public string EventImageUrl { get; set; }
        public int RemainingQuota { get; set; }

        // Kulüp adı
        public string ClubId { get; set; }
        public string ClubName { get; set; }
        public string OwnerId { get; set; }
    }

    // Bilet satın alma isteği
    public class PurchaseTicketDto
    {
        public Guid EventId { get; set; }
    }
}
