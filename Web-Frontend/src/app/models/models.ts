// ─────────────────────────────────────────────
// Backend DTOs ile birebir eşleşen TypeScript modelleri
// ─────────────────────────────────────────────

export interface AuthResponse {
  id: string;
  firstName: string;
  lastName: string;
  userName: string;
  email: string;
  roles: string[];
  isVerified: boolean;
  jwToken: string;
  refreshToken: string;
  userType: string; // 'student' | 'club'
  clubId?: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterStudentRequest {
  firstName: string;
  lastName: string;
  email: string;
  userName: string;
  password: string;
  confirmPassword: string;
  university?: string;
  department?: string;
}

export interface RegisterClubRequest {
  firstName: string;
  lastName: string;
  email: string;
  userName: string;
  password: string;
  confirmPassword: string;
  userType: 'club';
  clubName: string;
  advisorName: string;
  phoneNumber: string;
  referenceNumber: string;
  university: string;
}

// ─────────────────────────────────────────────
// CATEGORY
// ─────────────────────────────────────────────
export interface CategoryDto {
  id: string;
  name: string;
  description: string;
  iconName: string;
  colorHex: string;
  eventCount: number;
}

// ─────────────────────────────────────────────
// EVENT
// ─────────────────────────────────────────────
export interface EventListDto {
  id: string;
  title: string;
  ownerId: string;
  ownerName?: string;
  ownerInitials?: string;
  ownerFirstName?: string;
  ownerLastName?: string;
  ownerProfileImageUrl?: string;
  clubName?: string;
  clubInitials?: string;
  categoryName: string;
  price: number;
  date: string;
  imageUrl: string;
  likeCount: number;
  commentCount: number;
  isLikedByCurrentUser: boolean;
}

export interface EventDto {
  id: string;
  title: string;
  description: string;
  date: string;
  location: string;
  address: string;
  price: number;
  quota: number;
  remainingQuota: number;
  imageUrl: string;
  isActive: boolean;
  categoryId?: string;
  categoryName: string;
  ownerId: string;
  ownerName?: string;
  ownerInitials?: string;
  ownerFirstName?: string;
  ownerLastName?: string;
  ownerProfileImageUrl?: string;
  clubId?: string;
  clubName?: string;
  clubInitials?: string;
  likeCount: number;
  commentCount: number;
  ticketCount: number;
  isLikedByCurrentUser: boolean;
  hasTicket: boolean;
}

export interface CreateEventDto {
  title: string;
  description: string;
  date: string;
  location: string;
  address: string;
  price: number;
  quota: number;
  imageUrl: string;
  categoryId?: string;
  clubId?: string;
}

// ─────────────────────────────────────────────
// CLUB
// ─────────────────────────────────────────────
export interface ClubListDto {
  id: string;
  name: string;
  initials: string;
  category: string;
  followerCount: number;
  isFollowedByCurrentUser: boolean;
}

export interface ClubDto {
  id: string;
  name: string;
  initials: string;
  category: string;
  description: string;
  coverImageUrl: string;
  instagramHandle: string;
  followerCount: number;
  eventCount: number;
  isFollowedByCurrentUser: boolean;
}

export interface CreateClubDto {
  name: string;
  initials: string;
  category: string;
  description: string;
  coverImageUrl: string;
  instagramHandle: string;
}

// ─────────────────────────────────────────────
// TICKET
// ─────────────────────────────────────────────
export interface TicketDto {
  id: string;
  ticketNumber: string;
  qrCode: string;
  purchaseDate: string;
  isUsed: boolean;
  eventId: string;
  eventTitle: string;
  eventDate: string;
  eventLocation: string;
  eventImageUrl: string;
  clubName: string;
}

export interface PurchaseTicketDto {
  eventId: string;
}

export interface TicketCheckDto {
  hasTicket: boolean;
  remainingQuota: number;
}

// ─────────────────────────────────────────────
// COMMENT
// ─────────────────────────────────────────────
export interface CommentDto {
  id: string;
  content: string;
  createdAt: string;
  userFullName: string;
  userInitials: string;
  applicationUserId: string;
}

export interface CreateCommentDto {
  eventId: string;
  content: string;
}

// ─────────────────────────────────────────────
// NOTIFICATION
// ─────────────────────────────────────────────
export enum NotificationType {
  NewEvent = 1,
  TicketPurchased = 2,
  EventReminder = 3,
  EventCancelled = 4,
  ClubNewEvent = 5,
  General = 6
}

export interface NotificationDto {
  id: string;
  title: string;
  body: string;
  isRead: boolean;
  type: NotificationType;
  relatedEventId?: string;
  relatedClubId?: string;
  createdAt: string;
}

// ─────────────────────────────────────────────
// API Generic Response Wrapper
// ─────────────────────────────────────────────
export interface ApiResponse<T> {
  data: T;
  succeeded: boolean;
  message?: string;
  errors?: string[];
}
