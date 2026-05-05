// ─────────────────────────────────────────────
// Backend DTOs ile birebir eşleşen TypeScript modelleri
// ─────────────────────────────────────────────

export interface AuthResponse {
  id: string;
  firstName: string;
  lastName: string;
  userName: string;
  email: string;
  profileImageUrl?: string;
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
// ACCOUNT — ProfileDto & UpdateProfileRequest
// ─────────────────────────────────────────────
export interface ProfileDto {
  id: string;
  firstName: string;
  lastName: string;
  email?: string;
  userName: string;
  university?: string;
  department?: string;
  profileImageUrl?: string;
  userType: string; // 'student' | 'club'
  clubId?: string;
  clubName?: string;
  clubDescription?: string;
  clubCoverImageUrl?: string;
  clubInstagramHandle?: string;
  ticketCount: number;
  followingClubCount: number;
  createdEventCount: number;
  clubFollowerCount: number;
}

export interface UpdateProfileRequest {
  firstName?: string;
  lastName?: string;
  university?: string;
  department?: string;
  profileImageUrl?: string;
  clubName?: string;
  clubDescription?: string;
  clubCoverImageUrl?: string;
  clubInstagramHandle?: string;
}

export interface ChangePasswordRequest {
  currentPassword: string;
  newPassword: string;
}

export interface ResetPasswordRequest {
  email: string;
  token: string;
  password: string;
  confirmPassword: string;
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
  // Backend OrganizerName olarak dönüyor — her ikisini de destekle
  organizerName?: string;
  organizerInitials?: string;
  organizerProfileImageUrl?: string;
  // Eski alan adları (geriye dönük uyumluluk)
  ownerName?: string;
  ownerInitials?: string;
  ownerProfileImageUrl?: string;
  clubId?: string;
  clubName?: string;
  clubInitials?: string;
  clubProfileImageUrl?: string;
  categoryName: string;
  price: number;
  date: string;
  imageUrl: string;
  likeCount: number;
  commentCount?: number;
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
  // Backend OrganizerName olarak dönüyor — her ikisini de destekle
  organizerName?: string;
  organizerInitials?: string;
  organizerProfileImageUrl?: string;
  // Eski alan adları (geriye dönük uyumluluk)
  ownerName?: string;
  ownerInitials?: string;
  ownerProfileImageUrl?: string;
  clubId?: string;
  clubName?: string;
  clubInitials?: string;
  clubProfileImageUrl?: string;
  isClubFollowedByCurrentUser?: boolean;
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

export interface UpdateEventDto {
  title: string;
  description: string;
  date: string;
  location: string;
  address: string;
  price: number;
  quota: number;
  imageUrl: string;
  categoryId?: string;
  isActive: boolean;
}

// ─────────────────────────────────────────────
// CLUB
// ─────────────────────────────────────────────
export interface ClubListDto {
  id: string;
  name: string;
  initials: string;
  category: string;
  description?: string;
  profileImageUrl?: string;
  coverImageUrl?: string;
  followerCount: number;
  eventCount?: number;
  isFollowedByCurrentUser: boolean;
}

export interface ClubDto {
  id: string;
  name: string;
  initials: string;
  category: string;
  description: string;
  profileImageUrl?: string;
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

// Backend /clubs/{id}/follow endpoint'inin response'u
export interface FollowToggleResponse {
  isFollowing: boolean;   // normalize edilmiş (backend "following" dönebilir)
  followerCount: number;
  followingClubCount: number;
  message: string;
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
  clubId?: string;
  clubName?: string;
  ownerId?: string;
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
  userProfileImageUrl?: string;
  applicationUserId: string;
  parentCommentId?: string;
  replyToUserName?: string;
  replies?: CommentDto[];
}

export interface CreateCommentDto {
  eventId: string;
  content: string;
  parentCommentId?: string;
}

// ─────────────────────────────────────────────
// NOTIFICATION
// ─────────────────────────────────────────────
export enum NotificationType {
  NewEvent        = 1,
  TicketPurchased = 2,
  EventReminder   = 3,
  EventCancelled  = 4,
  ClubNewEvent    = 5,
  General         = 6,
  ClubFollowed    = 7,
  EventCommented  = 8,
  EventLiked      = 9
}

export interface NotificationDto {
  id: string;
  userId?: string;
  title: string;
  body: string;
  message?: string;       // backend bazen message alanı da dönüyor
  isRead: boolean;
  type: NotificationType;
  relatedEntityId?: string;
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
