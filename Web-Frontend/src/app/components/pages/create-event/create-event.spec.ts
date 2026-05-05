import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideRouter } from '@angular/router';

import { routes } from '../../../app.routes';
import { CreateEvent } from './create-event';

describe('CreateEvent', () => {
  let component: CreateEvent;
  let fixture: ComponentFixture<CreateEvent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CreateEvent],
      providers: [provideRouter(routes), provideHttpClient()]
    })
    .compileComponents();

    fixture = TestBed.createComponent(CreateEvent);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
