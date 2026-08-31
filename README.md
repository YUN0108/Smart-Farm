# Smart-Farm

Basys3 FPGA와 Verilog를 기반으로 한 스마트팜 자동 제어 팀 프로젝트(5인)<br/><br/>

온도·습도, 수위, 화재, 식물 높이 등의 센서 데이터를 실시간으로 측정<br/>  
측정된 환경 상태에 따라 창문, 환풍기, 워터 펌프, 히터 등의 장치를 자동 제어<br/>  
LCD와 LED를 통해 스마트팜 내부 상태 및 식물 성장 상태를 표시<br/>



## Development Environment

- Basys3 FPGA
- Verilog HDL
- Xilinx Vivado



## My Implementation

- DHT11 온·습도 데이터 수신 
- 온도 기반 서보모터 창문 제어
- 습도 기반 DC Motor PWM 제어
- 화재 감지 및 30ms 입력 필터링
- Buzzer 및 UART 경고 메시지 전송
- I2C LCD 온·습도 표시



## Portfolio
[Notion - Smart Farm Project](https://app.notion.com/p/SMART-FARM-Basys3-3b117756329b806d9d83d7bba2da8481)



## Video
[![Smart Farm Video](https://img.youtube.com/vi/1cfGyPeMJjA/0.jpg)](https://www.youtube.com/watch?v=1cfGyPeMJjA)
