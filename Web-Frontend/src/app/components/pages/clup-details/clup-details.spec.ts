import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ClupDetails } from './clup-details';

describe('ClupDetails', () => {
  let component: ClupDetails;
  let fixture: ComponentFixture<ClupDetails>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ClupDetails]
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
