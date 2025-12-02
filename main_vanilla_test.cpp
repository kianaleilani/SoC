/*****************************************************************//**
 * @file main_vanilla_test.cpp
 *
 * @brief Basic test of 4 basic i/o cores
 *
 * @author p chu
 * @version v1.0: initial release
 *********************************************************************/

//#define _DEBUG
#include "chu_init.h"
#include "gpio_cores.h"
#include "i2c_core.h"

/**
 * blink once per second for 5 times.
 * provide a sanity check for timer (based on SYS_CLK_FREQ)
 * @param led_p pointer to led instance
 */
void timer_check(GpoCore *led_p) {
   int i;

   for (i = 0; i < 5; i++) {
      led_p->write(0xffff);
      sleep_ms(500);
      led_p->write(0x0000);
      sleep_ms(500);
      debug("timer check - (loop #)/now: ", i, now_ms());
   }
}

/**
 * check individual led
 * @param led_p pointer to led instance
 * @param n number of led
 */
void led_check(GpoCore *led_p, int n) {
   int i;

   for (i = 0; i < n; i++) {
      led_p->write(1, i);
      sleep_ms(200);
      led_p->write(0, i);
      sleep_ms(200);
   }
}

/**
 * leds flash according to switch positions.
 * @param led_p pointer to led instance
 * @param sw_p pointer to switch instance
 */
void sw_check(GpoCore *led_p, GpiCore *sw_p) {
   int i, s;

   s = sw_p->read();
   for (i = 0; i < 30; i++) {
      led_p->write(s);
      sleep_ms(50);
      led_p->write(0);
      sleep_ms(50);
   }
}

/**
 * uart transmits test line.
 * @note uart instance is declared as global variable in chu_io_basic.h
 */
void uart_check() {
   static int loop = 0;

   uart.disp("uart test #");
   uart.disp(loop);
   uart.disp("\n\r");
   loop++;
}

#define TEMP_SENSOR_ADDR  0x48  // Example TMP102/LM75 address
#define TEMP_REG          0x00  // Temperature register

void test_temp_led(I2cCore *i2c, GpoCore *led)
{
   uint8_t write_buf[1];
   uint8_t read_buf[2];
   int status;
   float temperature;

   // Point to temperature register
   write_buf[0] = TEMP_REG;
   i2c->write_transaction(TEMP_SENSOR_ADDR << 1, write_buf, 1, 1);

   // Read 2 bytes
   status = i2c->read_transaction(TEMP_SENSOR_ADDR << 1, read_buf, 2, 0);
   if (status != 0) {
      // blink LEDs to indicate error
      led->write(0xAA);   // pattern 10101010
      sleep_ms(500);
      led->write(0x00);
      return;
   }

   // Convert to Celsius (TMP102/LM75 format)
   int16_t raw = (read_buf[0] << 8) | read_buf[1];
   raw >>= 4; // 12-bit value
   temperature = raw * 0.0625; // each LSB = 0.0625°C

   // Map temperature to LEDs
   // Example: turn on 1 LED per 5°C (max 8 LEDs)
   int level = (int)(temperature / 5.0);
   if (level > 8) level = 8;
   uint8_t led_pattern = (1 << level) - 1; // e.g., 3 LEDs on for 15°C


   led->write(led_pattern);
}

void test_rgb_leds(PwmCore *pwm)
{
    // Set PWM frequency (optional—only if you want to change it)
    pwm->set_freq(1000);

    // RED ON
    pwm->set_duty(1023, 0);   // Red
    pwm->set_duty(0, 1);     // Green
    pwm->set_duty(0, 2);     // Blue
    sleep_ms(5000);

    // GREEN ON
    pwm->set_duty(0, 0);
    pwm->set_duty(1023, 1);
    pwm->set_duty(0, 2);
    sleep_ms(5000);

    // BLUE ON
    pwm->set_duty(0, 0);
    pwm->set_duty(0, 1);
    pwm->set_duty(1023, 2);
    sleep_ms(5000);

    // ALL OFF
    pwm->set_duty(0, 0);
    pwm->set_duty(0, 1);
    pwm->set_duty(0, 2);
}

void test_temp_rgb(I2cCore *i2c, PwmCore *rgb)
{

   const uint8_t DEV_ADDR = 0x4b;
   uint8_t wbytes[2], bytes[2];
   //int ack;
   uint16_t tmp;
   float tmpC;

   // read adt7420 id register to verify device existence
   // ack = adt7420_p->read_dev_reg_byte(DEV_ADDR, 0x0b, &id);

   wbytes[0] = 0x0b;
   i2c->write_transaction(DEV_ADDR, wbytes, 1, 1);
   i2c->read_transaction(DEV_ADDR, bytes, 1, 0);
   uart.disp("read ADT7420 id (should be 0xcb): ");
   uart.disp(bytes[0], 16);
   uart.disp("\n\r");
   //debug("ADT check ack/id: ", ack, bytes[0]);
   // read 2 bytes
   //ack = adt7420_p->read_dev_reg_bytes(DEV_ADDR, 0x0, bytes, 2);
   wbytes[0] = 0x00;
   i2c->write_transaction(DEV_ADDR, wbytes, 1, 1);
   i2c->read_transaction(DEV_ADDR, bytes, 2, 0);

   // conversion
   tmp = (uint16_t) bytes[0];
   tmp = (tmp << 8) + (uint16_t) bytes[1];
   if (tmp & 0x8000) {
      tmp = tmp >> 3;
      tmpC = (float) ((int) tmp - 8192) / 16;
   } else {
      tmp = tmp >> 3;
      tmpC = (float) tmp / 16;
   }

   uart.disp("temperature (C): ");
   uart.disp(tmpC);
   uart.disp("\n\r");
   uart.disp(tmp);
   uart.disp("\n\r");


   // led
   if (tmpC < 36.000) {
      // cold
      rgb->set_duty(1023, 0);     
      rgb->set_duty(0, 1);     
      rgb->set_duty(0, 2);  
   }
   else if (tmpC >= 38.500) {
      // hot
      rgb->set_duty(0, 0);
      rgb->set_duty(0, 1);
      rgb->set_duty(1023, 2);
   }
   else {
      // Green normal
      rgb->set_duty(0, 0);  
      rgb->set_duty(1023, 1);
      rgb->set_duty(0, 2);
   }

   sleep_ms(1000);
}

/*
 * read temperature from adt7420
 * @param adt7420_p pointer to adt7420 instance
 */
void adt7420_check(I2cCore *adt7420_p, GpoCore *led_p) {
   const uint8_t DEV_ADDR = 0x4b;
   uint8_t wbytes[2], bytes[2];
   //int ack;
   uint16_t tmp;
   float tmpC;

   // read adt7420 id register to verify device existence
   // ack = adt7420_p->read_dev_reg_byte(DEV_ADDR, 0x0b, &id);

   wbytes[0] = 0x0b;
   adt7420_p->write_transaction(DEV_ADDR, wbytes, 1, 1);
   adt7420_p->read_transaction(DEV_ADDR, bytes, 1, 0);
   uart.disp("read ADT7420 id (should be 0xcb): ");
   uart.disp(bytes[0], 16);
   uart.disp("\n\r");
   //debug("ADT check ack/id: ", ack, bytes[0]);
   // read 2 bytes
   //ack = adt7420_p->read_dev_reg_bytes(DEV_ADDR, 0x0, bytes, 2);
   wbytes[0] = 0x00;
   adt7420_p->write_transaction(DEV_ADDR, wbytes, 1, 1);
   adt7420_p->read_transaction(DEV_ADDR, bytes, 2, 0);

   // conversion
   tmp = (uint16_t) bytes[0];
   tmp = (tmp << 8) + (uint16_t) bytes[1];
   if (tmp & 0x8000) {
      tmp = tmp >> 3;
      tmpC = (float) ((int) tmp - 8192) / 16;
   } else {
      tmp = tmp >> 3;
      tmpC = (float) tmp / 16;
   }
   uart.disp("temperature (C): ");
   uart.disp(tmpC);
   uart.disp("\n\r");
   led_p->write(tmp);
   sleep_ms(1000);
   led_p->write(0);
}






// instantiate switch, led
GpoCore led(get_slot_addr(BRIDGE_BASE, S2_LED));
GpiCore sw(get_slot_addr(BRIDGE_BASE, S10_SW));
I2cCore i2c(get_slot_addr(BRIDGE_BASE, S3_I2C));
PwmCore rgb_led1(get_slot_addr(BRIDGE_BASE, S14_RGB));


int main() {
 
      i2c.set_freq(100000); 
      led.write(0x00);
   while (1) {
      //timer_check(&led);
      //led_check(&led, 16);
      //sw_check(&led, &sw);
      //uart_check();
      //debug("main - switch value / up time : ", sw.read(), now_ms());
      
      //test_rgb_leds(&rgb_led1);

      //test_temp_led(&i2c, &led);



      //adt7420_check(&i2c, &led);

      test_temp_rgb(&i2c, &rgb_led1);



      sleep_ms(5000); // update once per second
   

   } //while
} //main

