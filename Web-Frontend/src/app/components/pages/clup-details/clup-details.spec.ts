import { ComponentFixture, TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideRouter } from '@angular/router';

import { routes } from '../../../app.routes';
import { ClupDetails } from './clup-details';

describe('ClupDetails', () => {
  let component: ClupDetails;
  let fixture: ComponentFixture<ClupDetails>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ClupDetails],
      providers: [provideRouter(routes), provideHttpClient()]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ClupDetails);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
