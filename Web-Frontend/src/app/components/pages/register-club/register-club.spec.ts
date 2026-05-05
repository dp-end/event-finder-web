import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideRouter } from '@angular/router';

import { RegisterClub } from './register-club';

describe('RegisterClub', () => {
  let component: RegisterClub;
  let fixture: ComponentFixture<RegisterClub>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [RegisterClub],
      providers: [provideRouter([]), provideHttpClient()]
    })
    .compileComponents();

    fixture = TestBed.createComponent(RegisterClub);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
