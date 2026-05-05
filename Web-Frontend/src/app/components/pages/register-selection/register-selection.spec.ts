import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideRouter } from '@angular/router';

import { RegisterSelection } from './register-selection';

describe('RegisterSelection', () => {
  let component: RegisterSelection;
  let fixture: ComponentFixture<RegisterSelection>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [RegisterSelection],
      providers: [provideRouter([]), provideHttpClient()]
    })
    .compileComponents();

    fixture = TestBed.createComponent(RegisterSelection);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
